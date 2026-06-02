export default function RightPanel() {
  const sections = [
    { title: '角色卡', desc: 'V2：角色信息、关系图谱' },
    { title: '设定卡', desc: 'V2：世界观、修炼体系' },
    { title: '大纲', desc: 'V2：故事大纲、卷纲' },
    { title: '伏笔', desc: 'V2：钩子追踪' },
  ]
  return (
    <div className="h-full flex flex-col">
      <div className="flex items-center px-4 flex-shrink-0 uppercase select-none" style={{ height: 35, background: 'var(--sidebar-bg)', borderBottom: '1px solid var(--sidebar-bg)', fontSize: 11, letterSpacing: 1.1, color: 'var(--text)' }}>
        写作参考
      </div>
      <div className="flex-1 overflow-y-auto p-2">
        {sections.map((s) => (
          <div key={s.title} className="p-2 mb-1 rounded" style={{ background: 'var(--input-bg)', border: '1px solid var(--border)' }}>
            <div style={{ fontSize: 12, color: 'var(--text)', marginBottom: 4 }}>{s.title}</div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{s.desc}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
