"use strict";
const electron = require("electron");
const electronAPI = {
  db: {
    query: (sql, params) => electron.ipcRenderer.invoke("db:query", sql, params),
    run: (sql, params) => electron.ipcRenderer.invoke("db:run", sql, params)
  },
  novel: {
    create: (title, description) => electron.ipcRenderer.invoke("novel:create", title, description),
    list: () => electron.ipcRenderer.invoke("novel:list"),
    get: (id) => electron.ipcRenderer.invoke("novel:get", id),
    delete: (id) => electron.ipcRenderer.invoke("novel:delete", id)
  },
  volume: {
    create: (novelId, title) => electron.ipcRenderer.invoke("volume:create", novelId, title),
    list: (novelId) => electron.ipcRenderer.invoke("volume:list", novelId),
    delete: (id) => electron.ipcRenderer.invoke("volume:delete", id)
  },
  chapter: {
    create: (novelId, volumeId, title) => electron.ipcRenderer.invoke("chapter:create", novelId, volumeId, title),
    list: (novelId) => electron.ipcRenderer.invoke("chapter:list", novelId),
    get: (id) => electron.ipcRenderer.invoke("chapter:get", id),
    read: (filePath) => electron.ipcRenderer.invoke("chapter:read", filePath),
    save: (filePath, content) => electron.ipcRenderer.invoke("chapter:save", filePath, content),
    delete: (id) => electron.ipcRenderer.invoke("chapter:delete", id)
  },
  snapshot: {
    create: (chapterId, content) => electron.ipcRenderer.invoke("snapshot:create", chapterId, content),
    list: (chapterId) => electron.ipcRenderer.invoke("snapshot:list", chapterId),
    get: (id) => electron.ipcRenderer.invoke("snapshot:get", id)
  },
  fs: {
    getDocumentsPath: () => electron.ipcRenderer.invoke("fs:getDocumentsPath"),
    getUserDataPath: () => electron.ipcRenderer.invoke("fs:getUserDataPath")
  }
};
electron.contextBridge.exposeInMainWorld("electronAPI", electronAPI);
