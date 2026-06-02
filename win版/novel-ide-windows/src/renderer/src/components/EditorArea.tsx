import Editor from '@monaco-editor/react'
import { useRef, useCallback, useEffect } from 'react'
import { useAppStore } from '../store'

const editorOptions = {
  wordWrap: 'on' as const, lineNumbers: 'off' as const, rulers: [300, 600],
  fontFamily: '"Noto Serif SC", "Microsoft YaHei", serif', fontSize: 18, lineHeight: 32,
  minimap: { enabled: false }, folding: false, smoothScrolling: true,
  cursorSmoothCaretAnimation: 'on' as const, renderLineHighlight: 'none' as const,
  padding: { top: 24, bottom: 24 }, scrollbar: { verticalScrollbarSize: 10, horizontalScrollbarSize: 10 },
  wordWrapColumn: 300, automaticLayout: true,
}

export default function EditorArea({ onToggleSidebar }: { onToggleSidebar: () => void }) {
  const editorRef = useRef<any>(null)
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const { currentChapter, editorContent, setEditorContent, theme } = useAppStore()

  useEffect(() => {
    if (!currentChapter) { setEditorContent(''); return }
    window.electronAPI?.chapter.read(currentChapter.file_path).then((c) => setEditorContent(c || ''))
  }, [currentChapter, setEditorContent])

  const handleChange = useCallback((value: string | undefined) => {
    const content = value || ''
    setEditorContent(content)
    if (saveTimerRef.current) clearTimeout(saveTimerRef.current)
    saveTimerRef.current = setTimeout(() => {
      if (currentChapter) window.electronAPI?.chapter.save(currentChapter.file_path, content)
    }, 800)
  }, [currentChapter, setEditorContent])

  const wordCount = editorContent.replace(/\s/g, '').length

  return (
    <div className="h-full flex flex-col" style={{ background: 'var(--editor-bg)' }}>
      <div className="flex items-center flex-shrink-0" style={{ background: 'var(--tab-inactive-bg)', height: 35, borderBottom: '1px solid var(--border)' }}>
        {currentChapter ? (
          <div className="flex items-center gap-1.5 px-3 h-full cursor-pointer" style={{ background: 'var(--tab-active-bg)', color: 'var(--text)', fontSize: 13, borderRight: '1px solid var(--border)' }}>
            <span style={{ fontSize: 12, opacity: 0.7 }}>📝</span>
            <span>{currentChapter.title}</span>
            <span className="ml-1" style={{ fontSize: 11, opacity: 0.4 }}>{wordCount}字</span>
            <span className="ml-2 opacity-40 hover:opacity-80" style={{ fontSize: 11 }}>✕</span>
          </div>
        ) : (
          <div className="flex items-center gap-1.5 px-3 h-full" style={{ background: 'var(--tab-active-bg)', color: 'var(--text-muted)', fontSize: 13, borderRight: '1px solid var(--border)' }}>
            <span style={{ fontSize: 12 }}>📄</span><span>开始</span>
          </div>
        )}
      </div>
      {currentChapter ? (
        <Editor height="100%" language="markdown" theme={theme === 'dark' ? 'vs-dark' : 'vs'} value={editorContent} onChange={handleChange} onMount={(e) => { editorRef.current = e }} options={editorOptions} />
      ) : (
        <div className="flex-1 flex items-center justify-center" style={{ color: 'var(--text-muted)' }}>
          <div className="text-center">
            <div style={{ fontSize: 48, opacity: 0.15, marginBottom: 16 }}>&#9998;</div>
            <div style={{ fontSize: 16, marginBottom: 8 }}>选择或创建一个章节开始写作</div>
            <div style={{ fontSize: 13, opacity: 0.5 }}>在左侧资源管理器中选择作品和章节</div>
          </div>
        </div>
      )}
    </div>
  )
}
