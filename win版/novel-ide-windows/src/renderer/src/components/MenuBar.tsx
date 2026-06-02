import { useAppStore } from '../store'

const menus = ['文件', '编辑', '选择', '查看', '前往', '运行', '终端', '帮助']

export default function MenuBar() {
  return (
    <div className="flex items-center select-none" style={{ height: 24, background: 'var(--menubar-bg)', borderBottom: '1px solid var(--border)', fontSize: 13, color: 'var(--text)' }}>
      {menus.map((m) => (
        <div key={m} className="h-full flex items-center px-3 cursor-pointer hover:bg-[var(--hover-bg)]">{m}</div>
      ))}
    </div>
  )
}
