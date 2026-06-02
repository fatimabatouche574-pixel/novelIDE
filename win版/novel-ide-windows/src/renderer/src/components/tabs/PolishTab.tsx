export default function PolishTab() {
  const presets = ['保持原意', '增强爽感', '减少废话', '加强画面感', '优化对话', '按番茄节奏']
  return (
    <div className="h-full flex flex-col gap-3">
      <div className="text-sm" style={{ color: 'var(--text-dim)' }}>一键精修</div>
      <div className="grid grid-cols-3 gap-2">
        {presets.map((p) => (
          <button key={p} className="px-3 py-2 rounded text-sm opacity-50" style={{ background: 'var(--input-bg)', color: 'var(--text-dim)', border: '1px solid var(--border)' }} disabled>{p}</button>
        ))}
      </div>
      <div className="flex-1 flex items-center justify-center text-sm" style={{ color: 'var(--text-muted)' }}>选中编辑器中的文字后，可进行精修</div>
    </div>
  )
}
