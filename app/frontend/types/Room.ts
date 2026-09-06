export interface RoomUser {
  id: number
  email: string
  role?: string
}

export interface RoomPermission {
  user_id: number
  user?: RoomUser
  permission_type: string
}

export interface RoomData {
  id: number
  name: string
  description?: string
  width: number
  height: number
  floor_plan_data?: any[]
  auto_checkout_enabled?: boolean
  auto_checkout_time?: string
  occupied_seat_count?: number
  seat_count?: number
  occupancy_rate?: number
}

export interface RoomCanvasEditorProps {
  room: RoomData
  shapes_data: any[]
  seats: any[]
  current_user: RoomUser
}

export interface RoomShowProps {
  room: RoomData
  seats: any[]
  is_room_creator: boolean
  has_permission: boolean
  permitted_users: RoomUser[]
  current_user: RoomUser
}
