import { useAppStore } from '../store'
import type { BottomTab } from '../types'
import ChatTab from './tabs/ChatTab'
import PolishTab from './tabs/PolishTab'
import ReviewTab from './tabs/ReviewTab'
import ModelTab from './tabs/ModelTab'
import LogTab from './tabs/LogTab'

const tabs: { key: BottomTab; label: string }[] = [
  { key: 'chat', label: '对话' }, { key: 'polish', label: '精修' }, { key: 'review', label: '审查' },
  { key: 'model', label: '模型' }, { key: 'log', label: '日志' },
]
const tabComponents: Record<BottomTab, React.FC> = { chat: ChatTab, polish: PolishTab, review: ReviewTab, model: ModelTab, log: LogTab }

export default function Panel() {
  const { activeBottomTab, setActiveBottomTab } = useAppStore()
  const ActiveTab = tabComponents[activeBottomTab]
  return (
    <div className="h-full flex flex-col" style={{ borderTop: '1px solid var(--border)', background: 'var(--panel-bg)' }}>
      <div className="flex items-center flex-shrink-0" style={{ height: 35 }}>
        <div className="flex items-center px-2 gap-1 flex-shrink-0" style={{ borderRight: '1px solid var(--border)' }}>
          <button className="w-5 h-5 flex items-center justify-center rounded hover:bg-[var(--hover-bg)]" style={{ fontSize: 10, color: 'var(--text-dim)' }}>↗</button>
        </div>
        {tabs.map((tab) => (
          <button key={tab.key} className="h-full px-3 flex items-center uppercase cursor-pointer hover:bg-[var(--hover-bg)]"
            style={{ fontSize: 11, letterSpacing: 0.5, color: activeBottomTab === tab.key ? 'var(--text-bright)' : 'var(--text-muted)', borderBottom: activeBottomTab === tab.key ? '1px solid var(--accent)' : '1px solid transparent', background: activeBottomTab === tab.key ? 'var(--panel-bg)' : 'transparent' }}
            onClick={() => setActiveBottomTab(tab.key)}>{tab.label}</button>
        ))}
      </div>
      <div className="flex-1 overflow-y-auto p-3" style={{ color: 'var(--text)' }}><ActiveTab /></div>
    </div>
  )
}
