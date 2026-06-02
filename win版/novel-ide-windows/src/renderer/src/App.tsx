import { useState, useCallback } from 'react'
import TitleBar from './components/TitleBar'
import MenuBar from './components/MenuBar'
import ActivityBar from './components/ActivityBar'
import Sidebar from './components/Sidebar'
import EditorArea from './components/EditorArea'
import RightPanel from './components/RightPanel'
import Panel from './components/Panel'
import StatusBar from './components/StatusBar'
import { useAppStore } from './store'

export default function App() {
  const [sidebarWidth, setSidebarWidth] = useState(260)
  const [rightWidth, setRightWidth] = useState(280)
  const [panelHeight, setPanelHeight] = useState(220)
  const [sidebarVisible, setSidebarVisible] = useState(true)
  const [isResizing, setIsResizing] = useState(false)
  const theme = useAppStore((s) => s.theme)

  const handleResize = useCallback((e: React.MouseEvent, setter: (v: number) => void, startVal: number, min: number, max: number, dir: 'left' | 'right' | 'up') => {
    e.preventDefault(); setIsResizing(true)
    const start = dir === 'up' ? e.clientY : e.clientX
    const onMove = (ev: MouseEvent) => {
      const cur = dir === 'up' ? ev.clientY : ev.clientX
      const delta = dir === 'right' ? (start - cur) : (cur - start)
      setter(Math.max(min, Math.min(max, startVal + delta)))
    }
    const onUp = () => { setIsResizing(false); document.removeEventListener('mousemove', onMove); document.removeEventListener('mouseup', onUp) }
    document.addEventListener('mousemove', onMove); document.addEventListener('mouseup', onUp)
  }, [])

  return (
    <div className={`flex flex-col h-screen w-screen ${isResizing ? 'resizing' : ''}`} data-theme={theme}>
      <TitleBar />
      <MenuBar />
      <div className="flex flex-1 min-h-0">
        <div className="flex flex-shrink-0" style={{ background: 'var(--activitybar-bg)' }}>
          <ActivityBar />
          {sidebarVisible && (
            <>
              <div className="overflow-hidden flex-shrink-0" style={{ width: sidebarWidth, background: 'var(--sidebar-bg)' }}>
                <Sidebar />
              </div>
              <div className="resize-handle-v" onMouseDown={(e) => handleResize(e, setSidebarWidth, sidebarWidth, 180, 450, 'left')} />
            </>
          )}
        </div>
        <div className="flex-1 flex flex-col min-w-0">
          <div className="flex-1 min-h-0"><EditorArea onToggleSidebar={() => setSidebarVisible(!sidebarVisible)} /></div>
          <div className="resize-handle-h" onMouseDown={(e) => handleResize(e, setPanelHeight, panelHeight, 100, 500, 'up')} />
          <div style={{ height: panelHeight }}><Panel /></div>
        </div>
        <div className="resize-handle-v" onMouseDown={(e) => handleResize(e, setRightWidth, rightWidth, 200, 450, 'right')} />
        <div className="overflow-hidden flex-shrink-0" style={{ width: rightWidth, background: 'var(--sidebar-bg)' }}>
          <RightPanel />
        </div>
      </div>
      <StatusBar />
    </div>
  )
}
