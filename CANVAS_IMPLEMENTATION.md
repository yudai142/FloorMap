# React + SVG Canvas エディタ実装ガイド

## 概要

FloorMap の座席配置図エディタを、Canvas 2D API から React + SVG ベースに移行しました。このドキュメントは、フェーズ1-2の実装内容と、フェーズ3以降の拡張方針をまとめています。

**最終更新:** 2026-09-05  
**実装期間:** フェーズ1-2（約2週間）  
**言語:** React 18 + TypeScript + Zustand

---

## アーキテクチャ概要

### 技術スタック

```
Frontend:
  - React 18.2.0 (UI フレームワーク)
  - TypeScript (型安全性)
  - Zustand (状態管理)
  - Immer (不変性管理)
  - SVG (ベクター描画)
  - Vite 8.2.1 (ビルドツール)
  - Inertia.js 2.0 (Rails ↔ React 通信)

Backend:
  - Rails 8.1.3
  - ActionCable (WebSocket リアルタイム同期)
  - PostgreSQL (floor_plan_data JSONB 保存)
```

### 層別アーキテクチャ

```
┌─────────────────────────────────────────┐
│   Pages (Inertia)                        │
│   - CanvasEditor.jsx (editor context)    │
│   - RoomShow.jsx (view context)          │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   Canvas コンポーネント                   │
│   - マウスイベント処理                   │
│   - 状態管理統合                         │
│   - SVG レンダリング                     │
└──────────────┬──────────────────────────┘
               │
      ┌────────┴────────┬─────────────┬──────────────┐
      │                 │             │              │
┌─────▼────────┐  ┌────▼──────┐  ┌──▼──────┐  ┌───▼──────┐
│ Custom Hooks │  │ Renderers  │  │ Utilities│  │ Store    │
│              │  │            │  │          │  │          │
│ useSeat      │  │ Shape      │  │snapToGrid│  │ Zustand  │
│ Management   │  │ Renderer   │  │distToLine│  │ Editor   │
│              │  │            │  │isInPoly  │  │ Store    │
│ useShape     │  │ Seat       │  │          │  │          │
│ Drawing      │  │ Renderer   │  │          │  │          │
│              │  │            │  │          │  │          │
│ useShape     │  │ Preview    │  │          │  │          │
│ Preview      │  │ Renderer   │  │          │  │          │
└──────────────┘  └────────────┘  └──────────┘  └──────────┘
      │                │                │             │
      └────────────────┴────────────────┴─────────────┘
               │
        ┌──────▼──────────┐
        │  Rails API      │
        │  - POST seats   │
        │  - DELETE seats │
        │  - PATCH floor  │
        │  - PATCH check  │
        └─────────────────┘
```

---

## ファイル構造

### ディレクトリ構成

```
app/frontend/
├── Pages/
│   └── Rooms/
│       └── CanvasEditor.jsx              # Inertia Page (editor context)
├── components/
│   └── Editor/
│       ├── Canvas.jsx                    # メインコンポーネント (350+ 行)
│       ├── Canvas.css                    # スタイル定義
│       ├── EditorToolbar.jsx             # ツールバーコンポーネント
│       ├── EditorToolbar.css             # ツールバースタイル
│       ├── ShapeRenderer.jsx             # 図形レンダリング
│       ├── SeatRenderer.jsx              # 座席レンダリング
│       ├── PreviewRenderer.jsx           # プレビューレンダリング
│       ├── hooks/
│       │   ├── useSeatManagement.ts      # 座席 CRUD (createSeat, deleteSeat, moveSeat)
│       │   ├── useShapeDrawing.ts        # 図形描画 (addLine, addRect, addCircle...)
│       │   └── useShapePreview.ts        # プレビュー表示 (updateLinePreview, clearPreview...)
│       └── utils/
│           └── snapToGrid.ts             # グリッド処理 (snapToGrid, snapLineToAxis, distanceToLine...)
├── store/
│   └── editorStore.ts                    # Zustand 状態管理 (300+ 行)
├── types/
│   ├── Canvas.ts                         # Canvas 型定義 (EditorState, Shape, Seat...)
│   └── Room.ts                           # Room データ型定義
└── entrypoints/
    └── application.jsx                   # エントリーポイント
```

---

## 主要コンポーネント解説

### Canvas.jsx - メインコンポーネント

**責務:**
- マウスイベント処理（down/move/up）
- ツール別の処理振り分け
- SVG レンダリング管理

**主要メソッド:**

```typescript
// マウス位置取得（ズーム対応）
const getMousePosition = (e) => {
  const rect = svgRef.current.getBoundingClientRect()
  return {
    x: Math.round((e.clientX - rect.left) / zoom),
    y: Math.round((e.clientY - rect.top) / zoom)
  }
}

// 座席ヒットテスト
const getSeatAtPoint = (x, y) => {
  return seats.find(seat => {
    const dx = x - seat.x
    const dy = y - seat.y
    return Math.sqrt(dx * dx + dy * dy) <= 15
  })
}

// 図形判定（距離計算）
const getShapeAtPoint = (x, y) => {
  // 直線・矢印: distanceToLine()
  // 矢形: 矩形判定
  // 円: 距離判定
  // テキスト: 矩形判定
  // ポリゴン: isPointInPolygon()
}
```

**イベントフロー:**

```
handleMouseDown
  ├─ Tool: 'seat'
  │   └─ createSeat(x, y)
  ├─ Tool: 'select'
  │   └─ setDragging({id, offsetX, offsetY})
  ├─ Tool: 'delete'
  │   ├─ deleteSeat(seatId)
  │   └─ deleteShape(shapeId)
  └─ Tool: 'line'|'rect'|'circle'|'arrow'|'polygon'
      └─ setDrawingStart({x, y})

handleMouseMove
  ├─ dragging && select mode
  │   └─ mergeSeat({...seat, x, y})  // ローカル更新
  └─ drawingStart && drawing mode
      └─ updatePreview(x, y)  // プレビュー表示

handleMouseUp
  ├─ dragging && select mode
  │   └─ moveSeat(seatId, x, y)  // API 呼び出し
  └─ drawingStart && drawing mode
      ├─ addLine/addRect/addCircle/addArrow(...)  // 図形追加
      └─ clearPreview()
```

### Zustand Store (editorStore.ts)

**状態構造:**

```typescript
interface EditorState {
  // Data
  shapes: Shape[]
  seats: Seat[]
  selectedElements: SelectedElement[]
  
  // UI State
  currentTool: ToolType           // 'select'|'seat'|'line'|'rectangle'|...
  drawMode: DrawMode              // 'click'|'drag'
  selectedColor: string           // '#3b82f6'
  zoom: number                    // 0.1 ~ 3.0
  showGrid: boolean
  hasUnsavedChanges: boolean
  
  // History
  history: HistoryEntry[]
  historyIndex: number
  
  // Drawing State
  isDrawing: boolean
  drawingStart?: {x, y}
  preview?: Partial<Shape>
  dragging?: {id, offsetX, offsetY}
  selectionBox?: {x, y, width, height}
  polygonPoints: {x, y}[]
  textInput?: {x, y, text}
  
  // Actions (自動生成 by immer)
  setCurrentTool: (tool) => void
  setZoom: (zoom) => void
  addShape: (shape) => void
  mergeSeat: (seat) => void
  undo: () => void
  redo: () => void
  saveToHistory: (seats, shapes) => void
}
```

**使用例:**

```typescript
const { shapes, currentTool, addShape, setZoom } = useEditorStore()

// 図形追加
useEditorStore.setState(state => {
  state.shapes.push(newShape)  // immer: 不変に見えるが内部で immutable update
})

// または Actions を使う
useEditorStore().addShape(newShape)
```

### Custom Hooks

#### useSeatManagement(roomId)

座席の CRUD 操作を担当。API 呼び出しと状態更新を統合。

```typescript
const { createSeat, deleteSeat, moveSeat } = useSeatManagement(room.id)

// 座席追加
await createSeat(x, y)
// POST /rooms/:id/seats.json
// Response: { id, label, x, y, occupied, ... }
// 内部: mergeSeat() で状態更新

// 座席移動
await moveSeat(seatId, newX, newY)
// PATCH /rooms/:id/seats/:id/position.json

// 座席削除
await deleteSeat(seatId)
// DELETE /rooms/:id/seats/:id.json
// 内部: removeSeat() で状態更新
```

**エラーハンドリング:**

```typescript
try {
  await createSeat(x, y)
} catch (err) {
  setAlert({ type: 'error', message: err.message })
  // "座席の追加に失敗しました"
}
```

#### useShapeDrawing()

図形の追加・保存を担当。

```typescript
const { addLine, addRectangle, addCircle, addArrow, addText, addPolygon } = useShapeDrawing()

// 直線追加
addLine(x1, y1, x2, y2)
// 内部: snapLineToAxis() で軸スナップ
// Shape追加 → History保存

// 矢形追加
addRectangle(x, y, width, height)

// テキスト追加
addText(x, y, "Your text here")
```

**History 統合:**

```typescript
const addLine = (x1, y1, x2, y2) => {
  const newLine = { id: `line-${Date.now()}`, ... }
  addShape(newLine)
  saveToHistory(seats, [...shapes, newLine])  // Undo/Redo 対応
}
```

#### useShapePreview()

描画中のプレビュー表示を担当。

```typescript
const { updateLinePreview, updateRectanglePreview, clearPreview } = useShapePreview()

// マウス移動時
if (drawingStart && currentTool === 'line') {
  updateLinePreview(drawingStart.x, drawingStart.y, x, y)
  // preview state に変更を反映
}

// マウスアップ時
clearPreview()
```

### Utility Functions (snapToGrid.ts)

**グリッド・軸スナップ:**

```typescript
// グリッドスナップ (10px 単位)
const snapped = snapToGrid(x, gridSize=10)  // x = 37 -> 40

// 直線の軸スナップ (水平・垂直に自動修正)
const {x2, y2} = snapLineToAxis(x1, y1, x2, y2, threshold=8)
// 例: (0, 0) → (100, 5) なら (100, 0) に修正
```

**距離・判定:**

```typescript
// 点と直線セグメント間の距離
const dist = distanceToLine(px, py, x1, y1, x2, y2)

// ポリゴン内判定 (ray casting)
const inside = isPointInPolygon(x, y, [{x, y}, ...])
```

### Renderer コンポーネント

#### ShapeRenderer.jsx

全図形タイプを SVG 要素で描画。

```jsx
<ShapeRenderer shape={shape} isSelected={isSelected} />

// 内部: shape.type に応じて、
// - line: <line>
// - rectangle: <rect>
// - circle: <circle>
// - arrow: <g> (line + polygon)
// - text: <text>
// - polygon: <polygon>
```

#### SeatRenderer.jsx

座席を円形で表示。右クリック削除対応。

```jsx
<SeatRenderer seat={seat} onDelete={deleteSeat} />

// 描画:
// - <circle r="12" fill={occupied ? '#f87171' : '#4ade80'} />
// - <text>{seat.label}</text>
// - 右クリック: confirm → deleteSeat()
```

#### PreviewRenderer.jsx

ドラッグ中のプレビュー表示。点線スタイル。

```jsx
<PreviewRenderer preview={preview} />

// 内部: preview.type に応じてプレビュー図形を描画
// strokeDasharray="5,5" で点線表示
```

---

## マウスイベント処理フロー

### ツール別の動作

| ツール | down | move | up | 説明 |
|--------|------|------|-----|------|
| **座席** | createSeat() | - | - | クリックで座席追加 |
| **選択** | setDragging() | mergeSeat(local) | moveSeat(API) | ドラッグで移動 |
| **削除** | deleteSeat() / deleteShape() | - | - | クリックで削除 |
| **直線** | setDrawingStart() | updatePreview() | addLine() | ドラッグで描画 |
| **矢形** | setDrawingStart() | updatePreview() | addRectangle() | ドラッグで描画 |
| **円** | setDrawingStart() | updatePreview() | addCircle() | ドラッグで描画 |
| **矢印** | setDrawingStart() | updatePreview() | addArrow() | ドラッグで描画 |
| **テキスト** | setTextInput() | - | - | テキスト入力ダイアログ |

### 状態遷移図

```
┌──────────────┐
│ Idle         │
│ (no action)  │
└──────┬───────┘
       │ handleMouseDown
       ▼
┌──────────────────────┐
│ Action Pending       │
│ (drawingStart set)   │
└──────┬───────────────┘
       │ handleMouseMove
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌────────────────┐  ┌──────────────┐
│ Dragging       │  │ Drawing      │
│ (seat moving)  │  │ (shape draw) │
└────────┬───────┘  └────────┬─────┘
         │                   │
         │ handleMouseUp     │ handleMouseUp
         ▼                   ▼
    moveSeat()          addShape()
         │                   │
         └───────┬───────────┘
                 ▼
         ┌──────────────┐
         │ Idle (saved) │
         └──────────────┘
```

---

## API 統合方法

### 座席 API

**座席追加:**
```http
POST /rooms/:room_id/seats.json
Content-Type: application/json
X-CSRF-Token: <token>

{
  "seat": {
    "position_x": 100,
    "position_y": 200,
    "seat_type": "regular"
  }
}

Response 201:
{
  "id": 5,
  "label": "A1",
  "x": 100,
  "y": 200,
  "occupied": false,
  "seat_type": "regular"
}
```

**座席移動:**
```http
PATCH /rooms/:room_id/seats/:seat_id/position.json
Content-Type: application/json

{
  "seat": {
    "position_x": 150,
    "position_y": 250
  }
}
```

**座席削除:**
```http
DELETE /rooms/:room_id/seats/:seat_id.json
```

### 床面図保存 API

```http
PATCH /rooms/:room_id/floor_plan.json
Content-Type: application/json

{
  "room": {
    "floor_plan_data": [
      {
        "id": "line-1725369600000",
        "type": "line",
        "x1": 10,
        "y1": 20,
        "x2": 100,
        "y2": 200,
        "color": "#3b82f6"
      },
      {
        "id": "rect-1725369601000",
        "type": "rectangle",
        "x": 50,
        "y": 100,
        "width": 200,
        "height": 150,
        "color": "#ef4444"
      }
    ]
  }
}
```

---

## パフォーマンス最適化

### 現在の最適化

✅ **Zustand with Immer**
- 不変性管理を自動化
- Redux Devtools 互換

✅ **useCallback**
- イベントハンドラ・関数の メモ化
- 不要な再レンダリング防止

✅ **React.memo**
- Renderer コンポーネントで実装可能

✅ **Vite ビルド**
- ツリーシェイキング (unused code 削除)
- Code splitting (lazy loading 可能)

### 今後の最適化ポイント

🔄 **仮想化**
- 座席・図形が 1000+ の場合
- `react-window` や `react-virtualized` 検討

🔄 **Web Workers**
- グリッド計算・ポリゴン判定を別スレッド化
- UI ブロッキング防止

🔄 **Canvas Offscreen Rendering**
- SVG 要素が多い場合
- Canvas へ変換して高速化

---

## デバッグ・開発ガイド

### ブラウザ DevTools

**Redux Devtools（Zustand 対応）:**
```javascript
// store/editorStore.ts に devtools 追加可能
import { devtools } from 'zustand/middleware'

export const useEditorStore = create<EditorState>()(
  devtools(immer((set) => ({...})))
)
```

**React DevTools:**
- Components タブで Zustand state 確認
- Profiler でレンダリング性能測定

### ローカルデバッグ

```bash
# Vite dev server
docker-compose exec web npm run dev

# ビルド確認
docker-compose exec web npm run build

# ブラウザ開く
open http://localhost:3000/rooms/:room_id/canvas_editor
```

### よくあるバグ・解決法

| 問題 | 原因 | 解決法 |
|------|------|--------|
| 座席が追加されない | API エラー | DevTools Network タブで 201 確認 |
| 図形が描画されない | Shape state 未更新 | Zustand devtools で shapes array 確認 |
| ドラッグが遅い | 再レンダリング多い | React Profiler でボトルネック特定 |
| CSRF token エラー | getCsrfToken() 失敗 | HTML meta tag 確認 |

---

## フェーズ3以降の拡張ポイント

### フェーズ3 (予定)

**Undo/Redo:**
- History Stack 制限（max 50）
- キーボード操作対応

**複数選択:**
- ドラッグで矩形選択
- 一括移動・削除

**リアルタイム同期:**
- ActionCable ブロードキャスト
- 複数ユーザー編集対応

### フェーズ4 (検討中)

**高度な描画機能:**
- 図形変形（resize, rotate）
- レイヤー管理
- グループ化

**UI/UX 向上:**
- ズーム時の自動フォーカス
- スクロールバー表示
- 座席・図形の詳細プロパティ編集

**パフォーマンス:**
- Web Workers で計算オフロード
- Canvas レンダリング混合

---

## 関連ファイル・リソース

- **Rails Controller:** `app/controllers/rooms_controller.rb`
  - `#canvas_editor` - Inertia Props
  - `#floor_plan` - PATCH エンドポイント

- **Rails Model:** `app/models/seat.rb`
  - `#canvas_data` - JSON 応答
  - `#grid_position_for` - グリッド計算

- **ActionCable:** `app/channels/rooms_channel.rb`
  - リアルタイム同期（フェーズ3）

- **Type Definitions:**
  - `app/frontend/types/Canvas.ts`
  - `app/frontend/types/Room.ts`

---

## まとめ

このドキュメントは、React + SVG Canvas エディタの実装基盤を整理したものです。

**主な設計ポイント:**
- ✅ Zustand で一元化された状態管理
- ✅ Custom Hooks で ビジネスロジック分離
- ✅ TypeScript で型安全性確保
- ✅ SVG + マウスイベント で柔軟な描画
- ✅ Rails API との密接な統合

**次ステップ:**
フェーズ3 では Undo/Redo とリアルタイム同期を追加し、複数ユーザーでの同時編集を実現します。

---

**作成日:** 2026-09-05  
**担当:** Claude Code  
**バージョン:** v0.2 (Phase 1-2 完成版)
