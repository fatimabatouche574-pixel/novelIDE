import { useState } from 'react'
import { useAppStore } from '../store'
import type { Chapter } from '../types'
import ExtensionsPanel from './ExtensionsPanel'

export default function Sidebar() {
  const { novels, volumes, chapters, currentNovel, currentChapter, setCurrentNovel, setCurrentChapter, activeSidebarPanel, theme } = useAppStore()
  const [expandedVolumes, setExpandedVolumes] = useState<Set<number>>(new Set())
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['novels']))

  const toggleVolume = (id: number) => {
    setExpandedVolumes((prev) => { const n = new Set(prev); n.has(id) ? n.delete(id) : n.add(id); return n })
  }

  const chaptersByVolume = new Map<number | null, Chapter[]>()
  for (const ch of chapters) {
    const key = ch.volume_id
    if (!chaptersByVolume.has(key)) chaptersByVolume.set(key, [])
    chaptersByVolume.get(key)!.push(ch)
  }

  // 插件市场面板
  if (activeSidebarPanel === 'extensions') {
    return <ExtensionsPanel />
  }

  // 搜索面板
  if (activeSidebarPanel === 'search') {
    return (
      <div className="h-full flex flex-col">
        <SectionHeader title="搜索" />
        <div className="flex-1 p-3">
          <input
            type="text" placeholder="搜索文件内容..."
            className="w-full px-2 py-1.5 rounded text-sm outline-none"
            style={{ background: 'var(--input-bg)', border: '1px solid var(--border)', color: 'var(--text)' }}
          />
        </div>
      </div>
    )
  }

  // 资源管理器
  if (!currentNovel) {
    return (
      <div className="h-full flex flex-col">
        <SectionHeader title="资源管理器" />
        <div className="flex-1 overflow-y-auto">
          <CollapseHeader title="作品" expanded={expandedSections.has('novels')} onToggle={() => toggleSection('novels', expandedSections, setExpandedSections)} count={novels.length}>
            {novels.length === 0 ? (
              <div className="px-6 py-3" style={{ fontSize: 12, color: 'var(--text-muted)' }}>暂无作品</div>
            ) : novels.map((n) => (
              <TreeItem key={n.id} label={n.title} onClick={() => setCurrentNovel(n)} />
            ))}
          </CollapseHeader>
        </div>
      </div>
    )
  }

  return (
    <div className="h-full flex flex-col">
      <div className="flex items-center px-4 flex-shrink-0 uppercase select-none" style={{ height: 35, background: 'var(--sidebar-bg)', borderBottom: '1px solid var(--sidebar-bg)', fontSize: 11, letterSpacing: 1.1, color: 'var(--text)' }}>
        <span className="mr-2 cursor-pointer normal-case" style={{ fontSize: 13, opacity: 0.6 }} onClick={() => setCurrentNovel(null)}>&#9664;</span>
        <span className="truncate">{currentNovel.title}</span>
        <span className="ml-auto text-xs opacity-50 hover:opacity-100 cursor-pointer">+</span>
      </div>
      <div className="flex-1 overflow-y-auto">
        {volumes.map((v) => (
          <div key={v.id}>
            <CollapseHeader title={v.title} expanded={expandedVolumes.has(v.id)} onToggle={() => toggleVolume(v.id)}>
              {(chaptersByVolume.get(v.id) || []).map((ch) => (
                <TreeItem key={ch.id} label={ch.title} active={currentChapter?.id === ch.id} onClick={() => setCurrentChapter(ch)} />
              ))}
            </CollapseHeader>
          </div>
        ))}
        {(chaptersByVolume.get(null) || []).length > 0 && (
          <div>{chaptersByVolume.get(null)!.map((ch) => (
            <TreeItem key={ch.id} label={ch.title} active={currentChapter?.id === ch.id} onClick={() => setCurrentChapter(ch)} />
          ))}</div>
        )}
        {chapters.length === 0 && <div className="px-4 py-3" style={{ fontSize: 12, color: 'var(--text-muted)' }}>暂无章节</div>}
      </div>
    </div>
  )
}

function SectionHeader({ title }: { title: string }) {
  return (
    <div className="flex items-center px-4 flex-shrink-0 uppercase select-none" style={{ height: 35, background: 'var(--sidebar-bg)', borderBottom: '1px solid var(--sidebar-bg)', fontSize: 11, letterSpacing: 1.1, color: 'var(--text)' }}>
      {title}
    </div>
  )
}

function CollapseHeader({ title, expanded, onToggle, count, children }: { title: string; expanded: boolean; onToggle: () => void; count?: number; children: React.ReactNode }) {
  return (
    <div>
      <div className="flex items-center px-2 cursor-pointer select-none hover:bg-[var(--hover-bg)]" style={{ height: 22, fontSize: 11, color: 'var(--text)', letterSpacing: 0.5 }} onClick={onToggle}>
        <span className="mr-1" style={{ fontSize: 8 }}>{expanded ? '▼' : '▶'}</span>
        {title}
        {count !== undefined && <span className="ml-1" style={{ fontSize: 10, color: 'var(--text-muted)' }}>({count})</span>}
        <span className="ml-auto text-xs opacity-50 hover:opacity-100" onClick={(e) => e.stopPropagation()}>+</span>
      </div>
      {expanded && <div>{children}</div>}
    </div>
  )
}

function TreeItem({ label, active, onClick }: { label: string; active?: boolean; onClick: () => void }) {
  return (
    <div
      className="px-4 py-0.5 cursor-pointer truncate hover:bg-[var(--hover-bg)]"
      style={{ fontSize: 13, color: active ? 'var(--text-bright)' : 'var(--text)', background: active ? 'var(--selected-bg)' : 'transparent' }}
      onClick={onClick}
    >
      {label}
    </div>
  )
}

function toggleSection(key: string, current: Set<string>, setter: (fn: (p: Set<string>) => Set<string>) => void) {
  setter((p) => { const n = new Set(p); n.has(key) ? n.delete(key) : n.add(key); return n })
}
