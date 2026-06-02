import { useAppStore } from '../store'

export default function ActivityBar() {
  const { activeSidebarPanel, setActiveSidebarPanel, toggleTheme, theme } = useAppStore()

  return (
    <div className="h-full flex flex-col justify-between py-1" style={{ width: 48, background: 'var(--activitybar-bg)' }}>
      <div className="flex flex-col items-center">
        <ActivityIcon title="资源管理器" active={activeSidebarPanel === 'explorer'} onClick={() => setActiveSidebarPanel('explorer')}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M17.5 0h-9L7 1.5V6H2.5L1 7.5v15.07L2.5 24h12.07L16 22.57V18h4.7l1.3-1.43V4.5L17.5 0zm0 2.12l2.38 2.38H17.5V2.12zm-3 20.38h-12v-15H7v9.07L8.5 18h6v4.5zm6-6h-12v-15H16V6h4.5v10.5z"/></svg>
        </ActivityIcon>
        <ActivityIcon title="搜索" active={activeSidebarPanel === 'search'} onClick={() => setActiveSidebarPanel('search')}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M15.25 0a8.25 8.25 0 00-6.18 13.72L1 21.79l1.42 1.42 8.07-8.07A8.25 8.25 0 1015.25 0zm0 15a6.75 6.75 0 110-13.5 6.75 6.75 0 010 13.5z"/></svg>
        </ActivityIcon>
        <ActivityIcon title="插件市场" active={activeSidebarPanel === 'extensions'} onClick={() => setActiveSidebarPanel('extensions')}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M20.5 11H19V7c0-1.1-.9-2-2-2h-4V3.5C13 2.12 11.88 1 10.5 1S8 2.12 8 3.5V5H4c-1.1 0-2 .9-2 2v3.8h1.5c1.38 0 2.5 1.12 2.5 2.5S4.88 15.8 3.5 15.8H2V20c0 1.1.9 2 2 2h3.8v-1.5c0-1.38 1.12-2.5 2.5-2.5s2.5 1.12 2.5 2.5V22H17c1.1 0 2-.9 2-2v-4h1.5c1.38 0 2.5-1.12 2.5-2.5S21.88 11 20.5 11z"/></svg>
        </ActivityIcon>
      </div>
      <div className="flex flex-col items-center">
        <ActivityIcon title={`当前: ${theme === 'dark' ? '暗色' : '亮色'} (点击切换)`} onClick={toggleTheme}>
          <span style={{ fontSize: 18 }}>{theme === 'dark' ? '🌙' : '☀️'}</span>
        </ActivityIcon>
      </div>
    </div>
  )
}

function ActivityIcon({ title, active, onClick, children }: { title: string; active?: boolean; onClick?: () => void; children: React.ReactNode }) {
  return (
    <div
      className="w-12 h-12 flex items-center justify-center cursor-pointer"
      style={{ opacity: active ? 1 : 0.4, borderLeft: active ? '2px solid #fff' : '2px solid transparent', color: '#fff' }}
      title={title}
      onClick={onClick}
    >
      {children}
    </div>
  )
}
