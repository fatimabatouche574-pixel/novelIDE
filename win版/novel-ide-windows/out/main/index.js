"use strict";
const electron = require("electron");
const path = require("path");
const initSqlJs = require("sql.js");
const fs = require("fs");
let db;
let dbPath;
async function initDatabase() {
  const SQL = await initSqlJs();
  const userDataPath = electron.app.getPath("userData");
  dbPath = path.join(userDataPath, "novel_ide.db");
  if (fs.existsSync(dbPath)) {
    const buffer = fs.readFileSync(dbPath);
    db = new SQL.Database(buffer);
  } else {
    db = new SQL.Database();
  }
  db.run(`
    CREATE TABLE IF NOT EXISTS novels (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT DEFAULT '',
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `);
  db.run(`
    CREATE TABLE IF NOT EXISTS volumes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      novel_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE
    )
  `);
  db.run(`
    CREATE TABLE IF NOT EXISTS chapters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      novel_id INTEGER NOT NULL,
      volume_id INTEGER,
      title TEXT NOT NULL,
      file_path TEXT NOT NULL,
      word_count INTEGER DEFAULT 0,
      sort_order INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE,
      FOREIGN KEY (volume_id) REFERENCES volumes(id) ON DELETE SET NULL
    )
  `);
  db.run(`
    CREATE TABLE IF NOT EXISTS snapshots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chapter_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
    )
  `);
  saveDatabase();
  console.log("Database initialized:", dbPath);
  return db;
}
function saveDatabase() {
  if (!db) return;
  const data = db.export();
  const buffer = Buffer.from(data);
  fs.writeFileSync(dbPath, buffer);
}
function queryAll(sql, params = []) {
  const stmt = db.prepare(sql);
  if (params.length > 0) stmt.bind(params);
  const results = [];
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
  stmt.free();
  return results;
}
function queryOne(sql, params = []) {
  const stmt = db.prepare(sql);
  if (params.length > 0) stmt.bind(params);
  let result = null;
  if (stmt.step()) {
    result = stmt.getAsObject();
  }
  stmt.free();
  return result;
}
function runSql(sql, params = []) {
  db.run(sql, params);
  const changes = db.getRowsModified();
  const lastRow = queryOne("SELECT last_insert_rowid() as id");
  saveDatabase();
  return { changes, lastInsertRowid: lastRow?.id || 0 };
}
function registerIpcHandlers() {
  electron.ipcMain.handle("novel:create", (_event, title, description) => {
    const result = runSql("INSERT INTO novels (title, description) VALUES (?, ?)", [title, description || ""]);
    return result.lastInsertRowid;
  });
  electron.ipcMain.handle("novel:list", () => {
    return queryAll("SELECT * FROM novels ORDER BY updated_at DESC");
  });
  electron.ipcMain.handle("novel:get", (_event, id) => {
    return queryOne("SELECT * FROM novels WHERE id = ?", [id]);
  });
  electron.ipcMain.handle("novel:delete", (_event, id) => {
    runSql("DELETE FROM novels WHERE id = ?", [id]);
    return true;
  });
  electron.ipcMain.handle("volume:create", (_event, novelId, title) => {
    const maxOrder = queryOne("SELECT COALESCE(MAX(sort_order), 0) as max_order FROM volumes WHERE novel_id = ?", [novelId]);
    const result = runSql("INSERT INTO volumes (novel_id, title, sort_order) VALUES (?, ?, ?)", [novelId, title, (maxOrder?.max_order || 0) + 1]);
    return result.lastInsertRowid;
  });
  electron.ipcMain.handle("volume:list", (_event, novelId) => {
    return queryAll("SELECT * FROM volumes WHERE novel_id = ? ORDER BY sort_order", [novelId]);
  });
  electron.ipcMain.handle("volume:delete", (_event, id) => {
    runSql("DELETE FROM volumes WHERE id = ?", [id]);
    return true;
  });
  electron.ipcMain.handle("chapter:create", (_event, novelId, volumeId, title) => {
    const chaptersDir = path.join(electron.app.getPath("documents"), "NovelIDE", String(novelId), "chapters");
    fs.mkdirSync(chaptersDir, { recursive: true });
    const maxOrder = queryOne("SELECT COALESCE(MAX(sort_order), 0) as max_order FROM chapters WHERE novel_id = ?", [novelId]);
    const order = (maxOrder?.max_order || 0) + 1;
    const fileName = `${String(order).padStart(3, "0")}_${title}.md`;
    const filePath = path.join(chaptersDir, fileName);
    fs.writeFileSync(filePath, "", "utf-8");
    const result = runSql(
      "INSERT INTO chapters (novel_id, volume_id, title, file_path, sort_order) VALUES (?, ?, ?, ?, ?)",
      [novelId, volumeId, title, filePath, order]
    );
    return result.lastInsertRowid;
  });
  electron.ipcMain.handle("chapter:list", (_event, novelId) => {
    return queryAll("SELECT * FROM chapters WHERE novel_id = ? ORDER BY sort_order", [novelId]);
  });
  electron.ipcMain.handle("chapter:get", (_event, id) => {
    return queryOne("SELECT * FROM chapters WHERE id = ?", [id]);
  });
  electron.ipcMain.handle("chapter:read", (_event, filePath) => {
    if (!fs.existsSync(filePath)) return "";
    return fs.readFileSync(filePath, "utf-8");
  });
  electron.ipcMain.handle("chapter:save", (_event, filePath, content) => {
    fs.writeFileSync(filePath, content, "utf-8");
    const wordCount = content.replace(/\s/g, "").length;
    runSql('UPDATE chapters SET word_count = ?, updated_at = datetime("now") WHERE file_path = ?', [wordCount, filePath]);
    return true;
  });
  electron.ipcMain.handle("chapter:delete", (_event, id) => {
    const chapter = queryOne("SELECT file_path FROM chapters WHERE id = ?", [id]);
    if (chapter && fs.existsSync(chapter.file_path)) {
      fs.unlinkSync(chapter.file_path);
    }
    runSql("DELETE FROM chapters WHERE id = ?", [id]);
    return true;
  });
  electron.ipcMain.handle("snapshot:create", (_event, chapterId, content) => {
    runSql("INSERT INTO snapshots (chapter_id, content) VALUES (?, ?)", [chapterId, content]);
    runSql(`
      DELETE FROM snapshots WHERE chapter_id = ? AND id NOT IN (
        SELECT id FROM snapshots WHERE chapter_id = ? ORDER BY created_at DESC LIMIT 50
      )
    `, [chapterId, chapterId]);
    return true;
  });
  electron.ipcMain.handle("snapshot:list", (_event, chapterId) => {
    return queryAll("SELECT id, chapter_id, created_at FROM snapshots WHERE chapter_id = ? ORDER BY created_at DESC", [chapterId]);
  });
  electron.ipcMain.handle("snapshot:get", (_event, id) => {
    return queryOne("SELECT * FROM snapshots WHERE id = ?", [id]);
  });
  electron.ipcMain.handle("fs:getDocumentsPath", () => {
    return electron.app.getPath("documents");
  });
  electron.ipcMain.handle("fs:getUserDataPath", () => {
    return electron.app.getPath("userData");
  });
}
let mainWindow = null;
function createWindow() {
  mainWindow = new electron.BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1e3,
    minHeight: 600,
    title: "网文写作IDE",
    backgroundColor: "#1e1e1e",
    webPreferences: {
      preload: path.join(__dirname, "../preload/index.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    },
    titleBarStyle: "hidden",
    titleBarOverlay: {
      color: "#3c3c3c",
      symbolColor: "#999999",
      height: 30
    }
  });
  if (process.env.ELECTRON_RENDERER_URL) {
    mainWindow.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    mainWindow.loadFile(path.join(__dirname, "../renderer/index.html"));
  }
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    electron.shell.openExternal(url);
    return { action: "deny" };
  });
  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}
electron.app.whenReady().then(async () => {
  await initDatabase();
  registerIpcHandlers();
  createWindow();
  electron.app.on("activate", () => {
    if (electron.BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});
electron.app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    electron.app.quit();
  }
});
