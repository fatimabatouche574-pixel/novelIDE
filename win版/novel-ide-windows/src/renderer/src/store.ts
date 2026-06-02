import { create } from 'zustand'
import type { Novel, Volume, Chapter, BottomTab } from './types'

export type Theme = 'dark' | 'light'

interface AppState {
  // 主题
  theme: Theme
  // 当前状态
  currentNovel: Novel | null
  currentChapter: Chapter | null
  novels: Novel[]
  volumes: Volume[]
  chapters: Chapter[]
  editorContent: string
  activeBottomTab: BottomTab
  activeSidebarPanel: 'explorer' | 'search' | 'extensions'

  // 操作
  setTheme: (theme: Theme) => void
  toggleTheme: () => void
  setCurrentNovel: (novel: Novel | null) => void
  setCurrentChapter: (chapter: Chapter | null) => void
  setNovels: (novels: Novel[]) => void
  setVolumes: (volumes: Volume[]) => void
  setChapters: (chapters: Chapter[]) => void
  setEditorContent: (content: string) => void
  setActiveBottomTab: (tab: BottomTab) => void
  setActiveSidebarPanel: (panel: 'explorer' | 'search' | 'extensions') => void
}

export const useAppStore = create<AppState>((set) => ({
  theme: 'dark',
  currentNovel: null,
  currentChapter: null,
  novels: [],
  volumes: [],
  chapters: [],
  editorContent: '',
  activeBottomTab: 'chat',
  activeSidebarPanel: 'explorer',

  setTheme: (theme) => {
    document.documentElement.setAttribute('data-theme', theme)
    set({ theme })
  },
  toggleTheme: () => set((s) => {
    const next = s.theme === 'dark' ? 'light' : 'dark'
    document.documentElement.setAttribute('data-theme', next)
    return { theme: next }
  }),
  setCurrentNovel: (novel) => set({ currentNovel: novel }),
  setCurrentChapter: (chapter) => set({ currentChapter: chapter }),
  setNovels: (novels) => set({ novels }),
  setVolumes: (volumes) => set({ volumes }),
  setChapters: (chapters) => set({ chapters }),
  setEditorContent: (content) => set({ editorContent: content }),
  setActiveBottomTab: (tab) => set({ activeBottomTab: tab }),
  setActiveSidebarPanel: (panel) => set({ activeSidebarPanel: panel }),
}))
