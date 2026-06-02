export default function LogTab() {
  const logs = [
    { level: 'INFO', color: '#4ec9b0', msg: '应用启动' },
    { level: 'INFO', color: '#4ec9b0', msg: 'SQLite 数据库初始化完成' },
    { level: 'DEBUG', color: '#569cd6', msg: '等待操作...' },
  ]
  return (
    <div className="h-full flex flex-col gap-2" style={{ fontFamily: '"Cascadia Code", "Consolas", monospace', fontSize: 12 }}>
      <div style={{ fontFamily: 'sans-serif', color: 'var(--text-dim)' }}>日志</div>
      <div className="flex-1 overflow-y-auto space-y-1">
        {logs.map((log, i) => (
          <div key={i} style={{ color: 'var(--text-muted)' }}><span style={{ color: log.color }}>[{log.level}]</span> {log.msg}</div>
        ))}
      </div>
    </div>
  )
}
