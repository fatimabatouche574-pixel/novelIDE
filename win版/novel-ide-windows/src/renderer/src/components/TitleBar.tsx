export default function TitleBar() {
  return (
    <div
      className="flex items-center select-none"
      style={{ height: 30, background: 'var(--titlebar-bg)', WebkitAppRegion: 'drag', fontSize: 12, color: 'var(--text-dim)', paddingLeft: 12, paddingRight: 140 }}
    >
      <span style={{ fontSize: 14, marginRight: 8 }}>📝</span>
      <span>网文写作IDE</span>
    </div>
  )
}
