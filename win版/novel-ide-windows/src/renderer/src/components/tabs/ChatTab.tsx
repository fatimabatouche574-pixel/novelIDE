export default function ChatTab() {
  return (
    <div className="h-full flex flex-col">
      <div className="flex-1 flex items-center justify-center text-sm" style={{ color: 'var(--text-muted)' }}>AI对话功能将在后续Sprint中实现</div>
      <div className="flex-shrink-0 flex gap-2 pt-2" style={{ borderTop: '1px solid var(--border)' }}>
        <input type="text" placeholder="输入消息..." className="flex-1 rounded px-3 py-1.5 text-sm outline-none" style={{ background: 'var(--input-bg)', border: '1px solid var(--border)', color: 'var(--text)' }} disabled />
        <button className="px-4 py-1.5 text-sm rounded opacity-50" style={{ background: 'var(--accent)', color: '#fff' }} disabled>发送</button>
      </div>
    </div>
  )
}
