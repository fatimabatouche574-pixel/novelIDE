import { useAppStore } from '../store'

export default function StatusBar() {
  const { currentNovel, currentChapter, editorContent } = useAppStore()
  const wordCount = editorContent.replace(/\s/g, '').length
  return (
    <div className="flex items-center justify-between px-2 flex-shrink-0 select-none" style={{ height: 22, background: 'var(--statusbar-bg)', color: '#fff', fontSize: 12 }}>
      <div className="flex items-center gap-3">
        <span className="flex items-center gap-1 px-1.5 h-full cursor-pointer hover:bg-white/10">
          <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1.5l6.5 5v7.5l-6.5 4.5L1.5 14V6.5z"/></svg>main
        </span>
        {currentChapter && <span className="flex items-center gap-1 px-1.5 h-full">{currentNovel?.title}</span>}
      </div>
      <div className="flex items-center gap-3">
        {currentChapter && <span className="px-1.5 h-full cursor-pointer hover:bg-white/10">{wordCount} 字</span>}
        <span className="px-1.5 h-full cursor-pointer hover:bg-white/10">Ln 1, Col 1</span>
        <span className="px-1.5 h-full cursor-pointer hover:bg-white/10">空格: 4</span>
        <span className="px-1.5 h-full cursor-pointer hover:bg-white/10">UTF-8</span>
        <span className="px-1.5 h-full cursor-pointer hover:bg-white/10">Markdown</span>
      </div>
    </div>
  )
}
