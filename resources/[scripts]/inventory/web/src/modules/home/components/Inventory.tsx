import { useState, useRef } from 'react'
import { useDrag, useDrop, useDragLayer } from 'react-dnd'
import { useListener } from '@/hooks/listener'
import { useNuiMutation } from '@/hooks/useNuiMutation'
import { cdn } from '@/utils/cdn'
import slotFrameImg from '@/assets/inventory/slot-frame.png'
import headerDecoImg from '@/assets/inventory/header-deco.png'
import waveDividerImg from '@/assets/inventory/wave-divider.png'
import iconMoveImg from '@/assets/inventory/icon-move.png'
import iconUseImg from '@/assets/inventory/icon-use.png'
import bagIconImg from '@/assets/inventory/icon-bag.png'

export interface InventoryItem {
  name: string
  label: string
  quantity: number
  image: string
  weight?: number
  metadata?: Record<string, unknown>
}

interface DragItem {
  index: number
  item: InventoryItem
}

const ITEM_TYPE = 'INVENTORY_ITEM'
const EMPTY_SLOTS: (InventoryItem | null)[] = Array(5).fill(null)
const inventoryImageModules = import.meta.glob('@/assets/inventory/*.{png,jpg,jpeg,webp,svg}', {
  eager: true,
  import: 'default',
}) as Record<string, string>

function normalizeImageKey(value: string): string {
  return value
    .trim()
    .replace(/\.[^.]+$/, '')
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '_')
}

const inventoryImageByKey = Object.entries(inventoryImageModules).reduce(
  (acc, [path, imagePath]) => {
    const fileName = path.split('/').pop() ?? ''
    const key = normalizeImageKey(fileName)
    acc[key] = imagePath
    return acc
  },
  {} as Record<string, string>,
)

function getItemImageSrc(image: string): string {
  const localImage = inventoryImageByKey[normalizeImageKey(image)]
  if (localImage) return localImage
  return cdn(image)
}

function SlotVisual({ item, index }: { item: InventoryItem | null; index: number }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div style={{ position: 'relative', width: 95, height: 74, overflow: 'hidden' }}>
        <img
          src={slotFrameImg}
          style={{
            position: 'absolute',
            inset: 0,
            width: '100%',
            height: '100%',
            objectFit: 'fill',
            pointerEvents: 'none',
          }}
          alt=""
        />
        <span
          style={{
            position: 'absolute',
            inset: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 64,
            fontWeight: 500,
            color: '#f8efff',
            opacity: 0.15,
            pointerEvents: 'none',
            lineHeight: 1,
          }}
        >
          {index + 1}
        </span>
        {item && (
          <>
            <img
              src={getItemImageSrc(item.image)}
              style={{
                position: 'absolute',
                width: 60,
                height: 60,
                left: '50%',
                top: '50%',
                transform: 'translate(-50%, -50%)',
                objectFit: 'contain',
                pointerEvents: 'none',
              }}
              alt={item.name}
            />
            <span
              style={{
                position: 'absolute',
                bottom: 6.5,
                left: '50%',
                transform: 'translateX(-50%)',
                fontSize: 12,
                fontWeight: 500,
                color: '#c8fe4e',
                pointerEvents: 'none',
                whiteSpace: 'nowrap',
              }}
            >
              {item.quantity}x
            </span>
          </>
        )}
      </div>
      <div
        style={{
          height: 16,
          background: 'rgba(248,239,255,0.1)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <span
          style={{
            maxWidth: '90%',
            fontSize: 10,
            fontWeight: 500,
            color: item ? '#f8efff' : 'rgba(248,239,255,0.35)',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            pointerEvents: 'none',
          }}
        >
          {item ? item.label : 'VAZIO'}
        </span>
      </div>
    </div>
  )
}

function DragPreview() {
  const { isDragging, dragItem, offset } = useDragLayer((monitor) => ({
    dragItem: monitor.getItem() as DragItem | null,
    offset: monitor.getSourceClientOffset(),
    isDragging: monitor.isDragging(),
  }))

  if (!isDragging || !offset || !dragItem?.item) return null

  return (
    <div
      style={{
        position: 'fixed',
        pointerEvents: 'none',
        zIndex: 9999,
        left: offset.x,
        top: offset.y,
        opacity: 0.9,
        fontFamily: "'Termina', 'Inter', sans-serif",
      }}
    >
      <SlotVisual item={dragItem.item} index={dragItem.index} />
    </div>
  )
}

function DropOutside({ onDrop }: { onDrop: (index: number) => void }) {
  const ref = useRef<HTMLDivElement>(null)

  const [{ isOver }, drop] = useDrop<DragItem, void, { isOver: boolean }>({
    accept: ITEM_TYPE,
    drop: (dragged) => onDrop(dragged.index),
    collect: (monitor) => ({ isOver: monitor.isOver() }),
  })

  drop(ref)

  return (
    <div
      ref={ref}
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 0,
        background: isOver ? 'rgba(255,80,80,0.08)' : 'transparent',
        transition: 'background 0.15s ease',
      }}
    />
  )
}

interface SlotProps {
  index: number
  item: InventoryItem | null
  selected: boolean
  onMove: (from: number, to: number) => void
  onSelect: (index: number) => void
}

function Slot({ index, item, selected, onMove, onSelect }: SlotProps) {
  const ref = useRef<HTMLDivElement>(null)

  const [{ isDragging }, drag] = useDrag({
    type: ITEM_TYPE,
    item: (): DragItem => ({ index, item: item! }),
    canDrag: () => item !== null,
    collect: (monitor) => ({ isDragging: monitor.isDragging() as boolean }),
  })

  const [{ isOver }, drop] = useDrop<DragItem, void, { isOver: boolean }>({
    accept: ITEM_TYPE,
    drop: (dragged) => onMove(dragged.index, index),
    collect: (monitor) => ({ isOver: monitor.isOver() }),
  })

  drag(drop(ref))

  return (
    <div
      ref={ref}
      onClick={() => onSelect(index)}
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 4,
        flexShrink: 0,
        cursor: item ? 'grab' : 'default',
        opacity: isDragging ? 0.35 : item ? 1 : 0.65,
        filter: isOver
          ? 'brightness(1.1) drop-shadow(0 0 0.1rem rgba(200,254,78,0.4))'
          : selected
            ? 'drop-shadow(0 0 0.4rem rgba(200,254,78,0.5))'
            : undefined,
      }}
    >
      <div style={{ position: 'relative', width: 95, height: 74, overflow: 'hidden' }}>
        <img
          src={slotFrameImg}
          style={{
            position: 'absolute',
            inset: 0,
            width: '100%',
            height: '100%',
            objectFit: 'fill',
            pointerEvents: 'none',
          }}
          alt=""
        />
        <span
          style={{
            position: 'absolute',
            inset: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 64,
            fontWeight: 500,
            color: '#f8efff',
            opacity: 0.15,
            pointerEvents: 'none',
            lineHeight: 1,
          }}
        >
          {index + 1}
        </span>
        {item && (
          <>
            <img
              src={getItemImageSrc(item.image)}
              style={{
                position: 'absolute',
                width: 60,
                height: 60,
                left: '50%',
                top: '50%',
                transform: 'translate(-50%, -50%)',
                objectFit: 'contain',
                pointerEvents: 'none',
              }}
              alt={item.name}
            />
            <span
              style={{
                position: 'absolute',
                bottom: 6.5,
                left: '50%',
                transform: 'translateX(-50%)',
                fontSize: 12,
                fontWeight: 500,
                color: '#c8fe4e',
                pointerEvents: 'none',
                whiteSpace: 'nowrap',
              }}
            >
              {item.quantity}x
            </span>
          </>
        )}
      </div>
      <div
        style={{
          height: 16,
          background: 'rgba(248,239,255,0.1)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <span
          style={{
            maxWidth: '90%',
            fontSize: 10,
            fontWeight: 500,
            color: item ? '#f8efff' : 'rgba(248,239,255,0.35)',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            pointerEvents: 'none',
          }}
        >
          {item ? item.label : 'VAZIO'}
        </span>
      </div>
    </div>
  )
}

export default function Inventory() {
  const [slots, setSlots] = useState<(InventoryItem | null)[]>(EMPTY_SLOTS)
  const [selectedSlot, setSelectedSlot] = useState<number | null>(null)
  const [quantity, setQuantity] = useState('')

  useListener<{ items: (InventoryItem | null)[] }>('setInventory', (data) => {
    setSlots(data.items)
    setSelectedSlot(null)
  })

  const swapSlots = useNuiMutation<void, { from: number; to: number }>({ event: 'swapSlots' })
  const useItemMutation = useNuiMutation<void, { slot: number }>({ event: 'useItem' })
  const moveItemMutation = useNuiMutation<void, { slot: number; quantity: number }>({
    event: 'moveItem',
  })

  const handleSwapSlots = (from: number, to: number) => {
    if (from === to) return
    setSlots((prev) => {
      const next = [...prev]
      ;[next[from], next[to]] = [next[to], next[from]]
      return next
    })
    swapSlots.mutate({ from, to })
  }

  const handleSelectSlot = (index: number) => {
    if (!slots[index]) {
      setSelectedSlot(null)
      return
    }
    setSelectedSlot((prev) => (prev === index ? null : index))
  }

  const handleUseItem = () => {
    if (selectedSlot === null || !slots[selectedSlot]) return
    useItemMutation.mutate({ slot: selectedSlot })
  }

  const handleMoveItem = () => {
    if (selectedSlot === null || !slots[selectedSlot]) return
    const qty = parseInt(quantity) || slots[selectedSlot]!.quantity
    moveItemMutation.mutate({ slot: selectedSlot, quantity: qty })
    setQuantity('')
  }

  const handleDropOutside = (index: number) => {
    console.log('handleDropOutside', index)
    const item = slots[index]
    if (!item) return
    moveItemMutation.mutate({ slot: index, quantity: item.quantity })
    setSlots((prev) => {
      const next = [...prev]
      next[index] = null
      return next
    })
    setSelectedSlot(null)
  }

  const hasSelection = selectedSlot !== null && slots[selectedSlot] !== null

  return (
    <>
      <DragPreview />
      <DropOutside onDrop={handleDropOutside} />

      <div style={{ fontFamily: "'Termina', 'Inter', sans-serif", width: 543, position: 'relative', zIndex: 1 }}>
        <div
          style={{
            height: 43,
            background: 'rgba(29,28,38,0.95)',
            padding: '0 1.8rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <img src={bagIconImg} style={{ width: 26, height: 26 }} alt="" />
            <span
              style={{ fontSize: 12, fontWeight: 500, color: '#f8efff', letterSpacing: '0.08em' }}
            >
              INVENTARIO
            </span>
          </div>
          <img src={headerDecoImg} style={{ width: 35, height: 13 }} alt="" />
        </div>

        <div
          style={{
            background: 'rgba(29,28,38,0.9)',
            padding: '1rem 1.8rem',
            display: 'flex',
            gap: 8,
          }}
        >
          {slots.map((item, i) => (
            <Slot
              key={i}
              index={i}
              item={item}
              selected={selectedSlot === i}
              onMove={handleSwapSlots}
              onSelect={handleSelectSlot}
            />
          ))}
        </div>

        <div
          style={{
            background: 'rgba(29,28,38,0.95)',
            padding: '0.8rem 1.8rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 18,
              padding: '0 0.9rem',
              height: 34,
              background: 'rgba(248,239,255,0.05)',
              flexShrink: 0,
            }}
          >
            <button
              onClick={handleMoveItem}
              disabled={!hasSelection}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                border: 'none',
                background: 'none',
                padding: 0,
                cursor: hasSelection ? 'pointer' : 'default',
                opacity: hasSelection ? 1 : 0.4,
                fontFamily: "'Termina', 'Inter', sans-serif",
              }}
            >
              <img src={iconMoveImg} style={{ width: 14, height: 20 }} alt="" />
              <span
                style={{ fontSize: 10, fontWeight: 500, color: '#f8efff', letterSpacing: '0.05em' }}
              >
                MOVER
              </span>
            </button>
            <button
              onClick={handleUseItem}
              disabled={!hasSelection}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                border: 'none',
                background: 'none',
                padding: 0,
                cursor: hasSelection ? 'pointer' : 'default',
                opacity: hasSelection ? 1 : 0.4,
                fontFamily: "'Termina', 'Inter', sans-serif",
              }}
            >
              <img src={iconUseImg} style={{ width: 14, height: 20 }} alt="" />
              <span
                style={{ fontSize: 10, fontWeight: 500, color: '#f8efff', letterSpacing: '0.05em' }}
              >
                USAR
              </span>
            </button>
          </div>

          <input
            type="number"
            min={1}
            placeholder="QUANTIDADE"
            className="inv-qty-input"
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            style={{
              width: 301,
              height: 34,
              background: 'transparent',
              border: '0.1rem solid rgba(248,239,255,0.25)',
              color: '#f8efff',
              fontSize: 10,
              fontFamily: "'Termina', 'Inter', sans-serif",
              fontWeight: 500,
              padding: '0 1.2rem',
              outline: 'none',
              letterSpacing: '0.05em',
            }}
          />
        </div>

        <div style={{ height: 17, overflow: 'hidden' }}>
          <img
            src={waveDividerImg}
            style={{ width: '100%', height: '100%', objectFit: 'fill' }}
            alt=""
          />
        </div>
      </div>
    </>
  )
}
