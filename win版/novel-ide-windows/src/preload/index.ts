import { contextBridge, ipcRenderer } from 'electron'

export interface ElectronAPI {
  db: {
    query: (sql: string, params?: any[]) => Promise<any[]>
    run: (sql: string, params?: any[]) => Promise<any>
  }
  novel: {
    create: (title: string, description?: string) => Promise<number>
    list: () => Promise<any[]>
    get: (id: number) => Promise<any>
    delete: (id: number) => Promise<boolean>
  }
  volume: {
    create: (novelId: number, title: string) => Promise<number>
    list: (novelId: number) => Promise<any[]>
    delete: (id: number) => Promise<boolean>
  }
  chapter: {
    create: (novelId: number, volumeId: number | null, title: string) => Promise<number>
    list: (novelId: number) => Promise<any[]>
    get: (id: number) => Promise<any>
    read: (filePath: string) => Promise<string>
    save: (filePath: string, content: string) => Promise<boolean>
    delete: (id: number) => Promise<boolean>
  }
  snapshot: {
    create: (chapterId: number, content: string) => Promise<boolean>
    list: (chapterId: number) => Promise<any[]>
    get: (id: number) => Promise<any>
  }
  fs: {
    getDocumentsPath: () => Promise<string>
    getUserDataPath: () => Promise<string>
  }
}

const electronAPI: ElectronAPI = {
  db: {
    query: (sql, params) => ipcRenderer.invoke('db:query', sql, params),
    run: (sql, params) => ipcRenderer.invoke('db:run', sql, params),
  },
  novel: {
    create: (title, description) => ipcRenderer.invoke('novel:create', title, description),
    list: () => ipcRenderer.invoke('novel:list'),
    get: (id) => ipcRenderer.invoke('novel:get', id),
    delete: (id) => ipcRenderer.invoke('novel:delete', id),
  },
  volume: {
    create: (novelId, title) => ipcRenderer.invoke('volume:create', novelId, title),
    list: (novelId) => ipcRenderer.invoke('volume:list', novelId),
    delete: (id) => ipcRenderer.invoke('volume:delete', id),
  },
  chapter: {
    create: (novelId, volumeId, title) => ipcRenderer.invoke('chapter:create', novelId, volumeId, title),
    list: (novelId) => ipcRenderer.invoke('chapter:list', novelId),
    get: (id) => ipcRenderer.invoke('chapter:get', id),
    read: (filePath) => ipcRenderer.invoke('chapter:read', filePath),
    save: (filePath, content) => ipcRenderer.invoke('chapter:save', filePath, content),
    delete: (id) => ipcRenderer.invoke('chapter:delete', id),
  },
  snapshot: {
    create: (chapterId, content) => ipcRenderer.invoke('snapshot:create', chapterId, content),
    list: (chapterId) => ipcRenderer.invoke('snapshot:list', chapterId),
    get: (id) => ipcRenderer.invoke('snapshot:get', id),
  },
  fs: {
    getDocumentsPath: () => ipcRenderer.invoke('fs:getDocumentsPath'),
    getUserDataPath: () => ipcRenderer.invoke('fs:getUserDataPath'),
  },
}

contextBridge.exposeInMainWorld('electronAPI', electronAPI)
