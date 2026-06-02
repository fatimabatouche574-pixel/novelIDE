import { ipcMain } from 'electron'
import { queryAll, queryOne, runSql } from './db'
import fs from 'fs'
import path from 'path'
import { app } from 'electron'

export function registerIpcHandlers(): void {
  // ===== 作品 CRUD =====
  ipcMain.handle('novel:create', (_event, title: string, description?: string) => {
    const result = runSql('INSERT INTO novels (title, description) VALUES (?, ?)', [title, description || ''])
    return result.lastInsertRowid
  })

  ipcMain.handle('novel:list', () => {
    return queryAll('SELECT * FROM novels ORDER BY updated_at DESC')
  })

  ipcMain.handle('novel:get', (_event, id: number) => {
    return queryOne('SELECT * FROM novels WHERE id = ?', [id])
  })

  ipcMain.handle('novel:delete', (_event, id: number) => {
    runSql('DELETE FROM novels WHERE id = ?', [id])
    return true
  })

  // ===== 卷 CRUD =====
  ipcMain.handle('volume:create', (_event, novelId: number, title: string) => {
    const maxOrder = queryOne('SELECT COALESCE(MAX(sort_order), 0) as max_order FROM volumes WHERE novel_id = ?', [novelId])
    const result = runSql('INSERT INTO volumes (novel_id, title, sort_order) VALUES (?, ?, ?)', [novelId, title, (maxOrder?.max_order || 0) + 1])
    return result.lastInsertRowid
  })

  ipcMain.handle('volume:list', (_event, novelId: number) => {
    return queryAll('SELECT * FROM volumes WHERE novel_id = ? ORDER BY sort_order', [novelId])
  })

  ipcMain.handle('volume:delete', (_event, id: number) => {
    runSql('DELETE FROM volumes WHERE id = ?', [id])
    return true
  })

  // ===== 章节 CRUD =====
  ipcMain.handle('chapter:create', (_event, novelId: number, volumeId: number | null, title: string) => {
    const chaptersDir = path.join(app.getPath('documents'), 'NovelIDE', String(novelId), 'chapters')
    fs.mkdirSync(chaptersDir, { recursive: true })

    const maxOrder = queryOne('SELECT COALESCE(MAX(sort_order), 0) as max_order FROM chapters WHERE novel_id = ?', [novelId])
    const order = (maxOrder?.max_order || 0) + 1
    const fileName = `${String(order).padStart(3, '0')}_${title}.md`
    const filePath = path.join(chaptersDir, fileName)

    fs.writeFileSync(filePath, '', 'utf-8')

    const result = runSql(
      'INSERT INTO chapters (novel_id, volume_id, title, file_path, sort_order) VALUES (?, ?, ?, ?, ?)',
      [novelId, volumeId, title, filePath, order]
    )
    return result.lastInsertRowid
  })

  ipcMain.handle('chapter:list', (_event, novelId: number) => {
    return queryAll('SELECT * FROM chapters WHERE novel_id = ? ORDER BY sort_order', [novelId])
  })

  ipcMain.handle('chapter:get', (_event, id: number) => {
    return queryOne('SELECT * FROM chapters WHERE id = ?', [id])
  })

  ipcMain.handle('chapter:read', (_event, filePath: string) => {
    if (!fs.existsSync(filePath)) return ''
    return fs.readFileSync(filePath, 'utf-8')
  })

  ipcMain.handle('chapter:save', (_event, filePath: string, content: string) => {
    fs.writeFileSync(filePath, content, 'utf-8')
    const wordCount = content.replace(/\s/g, '').length
    runSql('UPDATE chapters SET word_count = ?, updated_at = datetime("now") WHERE file_path = ?', [wordCount, filePath])
    return true
  })

  ipcMain.handle('chapter:delete', (_event, id: number) => {
    const chapter = queryOne('SELECT file_path FROM chapters WHERE id = ?', [id])
    if (chapter && fs.existsSync(chapter.file_path)) {
      fs.unlinkSync(chapter.file_path)
    }
    runSql('DELETE FROM chapters WHERE id = ?', [id])
    return true
  })

  // ===== 快照 =====
  ipcMain.handle('snapshot:create', (_event, chapterId: number, content: string) => {
    runSql('INSERT INTO snapshots (chapter_id, content) VALUES (?, ?)', [chapterId, content])
    // 保留最近50个快照
    runSql(`
      DELETE FROM snapshots WHERE chapter_id = ? AND id NOT IN (
        SELECT id FROM snapshots WHERE chapter_id = ? ORDER BY created_at DESC LIMIT 50
      )
    `, [chapterId, chapterId])
    return true
  })

  ipcMain.handle('snapshot:list', (_event, chapterId: number) => {
    return queryAll('SELECT id, chapter_id, created_at FROM snapshots WHERE chapter_id = ? ORDER BY created_at DESC', [chapterId])
  })

  ipcMain.handle('snapshot:get', (_event, id: number) => {
    return queryOne('SELECT * FROM snapshots WHERE id = ?', [id])
  })

  // ===== 文件系统 =====
  ipcMain.handle('fs:getDocumentsPath', () => {
    return app.getPath('documents')
  })

  ipcMain.handle('fs:getUserDataPath', () => {
    return app.getPath('userData')
  })
}
