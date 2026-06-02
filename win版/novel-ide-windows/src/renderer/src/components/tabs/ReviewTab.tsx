export default function ReviewTab() {
  const tools = [{ name: '设定提醒', status: 'V2' }, { name: '爽点检查', status: 'V2' }, { name: '水文检测', status: 'V2' }]
  return (
    <div className="h-full flex flex-col gap-3">
      <div className="text-sm" style={{ color: 'var(--text-dim)' }}>审查工具</div>
      <div className="space-y-1">
        {tools.map((t) => (
          <div key={t.name} className="flex items-center justify-between p-2 rounded text-sm" style={{ background: 'var(--input-bg)', border: '1px solid var(--border)' }}>
            <span style={{ color: 'var(--text-dim)' }}>{t.name}</span>
            <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>{t.status}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
