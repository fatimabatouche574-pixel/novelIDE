export default function ModelTab() {
  return (
    <div className="h-full flex flex-col gap-3">
      <div className="text-sm" style={{ color: 'var(--text-dim)' }}>模型配置</div>
      <div className="p-3 rounded" style={{ background: 'var(--input-bg)', border: '1px solid var(--border)' }}>
        <div className="text-sm mb-1" style={{ color: 'var(--text)' }}>API Key 设置</div>
        <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>支持 DeepSeek / Claude / GPT 等</div>
        <input type="password" placeholder="请输入 API Key" className="mt-2 w-full rounded px-3 py-1.5 text-sm outline-none" style={{ background: 'var(--editor-bg)', border: '1px solid var(--border)', color: 'var(--text)' }} disabled />
      </div>
      <div className="p-3 rounded" style={{ background: 'var(--input-bg)', border: '1px solid var(--border)' }}>
        <div className="text-sm mb-1" style={{ color: 'var(--text)' }}>本地模型</div>
        <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>支持 Ollama / LM Studio</div>
      </div>
    </div>
  )
}
