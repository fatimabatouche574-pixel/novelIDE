export interface Novel {
  id: number
  title: string
  description: string
  created_at: string
  updated_at: string
}

export interface Volume {
  id: number
  novel_id: number
  title: string
  sort_order: number
  created_at: string
}

export interface Chapter {
  id: number
  novel_id: number
  volume_id: number | null
  title: string
  file_path: string
  word_count: number
  sort_order: number
  created_at: string
  updated_at: string
}

export interface Snapshot {
  id: number
  chapter_id: number
  created_at: string
}

export type BottomTab = 'chat' | 'polish' | 'review' | 'model' | 'log'
