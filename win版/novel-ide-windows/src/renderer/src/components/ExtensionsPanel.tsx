import { useAppStore } from '../store'

const extensions = [
  { name: '番茄AI助手', author: 'NovelIDE', desc: '番茄小说平台AI写作预设和Agent', installed: false, downloads: '12.3k', icon: '🍅' },
  { name: '暗色护眼主题', author: 'Community', desc: '低蓝光护眼暗色主题', installed: false, downloads: '8.1k', icon: '🌙' },
  { name: '拼音输入提示', author: 'NovelIDE', desc: '写作时提供拼音和同义词提示', installed: false, downloads: '5.6k', icon: '💡' },
  { name: '网文排版工具', author: 'Community', desc: '按起点/番茄/飞卢格式排版', installed: true, downloads: '15.2k', icon: '📐' },
  { name: '角色关系图谱', author: 'NovelIDE', desc: '可视化角色关系网络', installed: false, downloads: '3.4k', icon: '🕸️' },
  { name: 'AI续写增强', author: 'Community', desc: '更智能的AI续写和润色', installed: false, downloads: '22.1k', icon: '✨' },
]

export default function ExtensionsPanel() {
  const theme = useAppStore((s) => s.theme)

  return (
    <div className="h-full flex flex-col">
      {/* 标题 */}
      <div className="flex items-center px-4 flex-shrink-0 uppercase select-none" style={{ height: 35, background: 'var(--sidebar-bg)', borderBottom: '1px solid var(--sidebar-bg)', fontSize: 11, letterSpacing: 1.1, color: 'var(--text)' }}>
        插件市场
      </div>

      {/* 搜索框 */}
      <div className="p-2 flex-shrink-0">
        <input
          type="text"
          placeholder="搜索插件..."
          className="w-full px-2 py-1.5 rounded text-sm outline-none"
          style={{ background: 'var(--input-bg)', border: '1px solid var(--border)', color: 'var(--text)' }}
        />
      </div>

      {/* 分类标签 */}
      <div className="flex items-center gap-2 px-2 pb-2 flex-shrink-0">
        {['全部', '推荐', 'AI工具', '主题', '排版'].map((tag, i) => (
          <span
            key={tag}
            className="px-2 py-0.5 rounded text-xs cursor-pointer"
            style={{
              background: i === 0 ? 'var(--accent)' : 'var(--input-bg)',
              color: i === 0 ? '#fff' : 'var(--text-dim)',
              border: '1px solid var(--border)',
            }}
          >
            {tag}
          </span>
        ))}
      </div>

      {/* 插件列表 */}
      <div className="flex-1 overflow-y-auto px-2">
        {extensions.map((ext) => (
          <div
            key={ext.name}
            className="p-3 mb-1 rounded cursor-pointer hover:bg-[var(--hover-bg)]"
            style={{ border: '1px solid var(--border)' }}
          >
            <div className="flex items-start gap-2">
              <span style={{ fontSize: 24 }}>{ext.icon}</span>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span style={{ fontSize: 13, color: 'var(--text-bright)', fontWeight: 500 }}>{ext.name}</span>
                  <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>by {ext.author}</span>
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-dim)', marginTop: 2 }}>{ext.desc}</div>
                <div className="flex items-center gap-3 mt-1.5">
                  <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>⬇ {ext.downloads}</span>
                  <button
                    className="px-3 py-0.5 rounded text-xs"
                    style={{
                      background: ext.installed ? 'var(--hover-bg)' : 'var(--accent)',
                      color: ext.installed ? 'var(--text-dim)' : '#fff',
                      border: ext.installed ? '1px solid var(--border)' : 'none',
                    }}
                  >
                    {ext.installed ? '已安装' : '安装'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
