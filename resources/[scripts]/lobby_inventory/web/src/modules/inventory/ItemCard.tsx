import { useState } from 'react'
import { Coins, ImageOff, Lock, ShieldX } from 'lucide-react'
import { cn } from '@/lib/utils'
import { getRarityColor, getRarityLabel } from '@inventario/utils/rarity'
import type { InventarioItem } from './types'

export type ItemAction = 'equip' | 'unequip' | 'buy' | 'none'

export interface ItemCardProps {
  item: InventarioItem
  owned: boolean
  equipped: boolean
  /** Action label shown on the primary button; controlled by the page. */
  action: ItemAction
  /** Disabled state (e.g. server pending, incompatible model). */
  disabled?: boolean
  onAction?: (item: InventarioItem, action: ItemAction) => void
}

function StatusBadge({
  label,
  color,
  textColor = '#f8efff',
}: {
  label: string
  color: string
  textColor?: string
}) {
  return (
    <span
      className="rounded px-1.5 py-0.5 text-[0.95rem] font-semibold uppercase tracking-wider"
      style={{ backgroundColor: color, color: textColor }}
    >
      {label}
    </span>
  )
}

export default function ItemCard({
  item,
  owned,
  equipped,
  action,
  disabled,
  onAction,
}: ItemCardProps) {
  const [imgError, setImgError] = useState(false)
  const rarityColor = getRarityColor(item.rarity)
  const incompatible = !!item.incompatible
  const showImage = !!item.image && !imgError

  const actionLabel: Record<ItemAction, string> = {
    equip: 'Equipar',
    unequip: 'Desequipar',
    buy: 'Comprar',
    none: '—',
  }

  const actionDisabled = disabled || action === 'none' || incompatible

  return (
    <div
      className={cn(
        'group relative flex flex-col overflow-hidden rounded-lg border bg-white/[0.02] transition-colors',
        equipped ? 'border-primary/60' : 'border-white/10 hover:border-white/25',
      )}
    >
      {/* Rarity stripe — purely cosmetic */}
      <div
        className="h-[0.25rem] w-full shrink-0"
        style={{ backgroundColor: rarityColor }}
      />

      {/* Image area */}
      <div className="relative flex h-[14rem] items-center justify-center overflow-hidden bg-gradient-to-b from-[#1e1f26] to-[#0f0f12]">
        {showImage ? (
          <img
            src={item.image as string}
            alt={item.name}
            className="h-full w-full object-contain"
            onError={() => setImgError(true)}
          />
        ) : (
          <ImageOff size={48} className="text-white/15" />
        )}

        {/* Top-left rarity badge */}
        <div className="absolute left-2 top-2">
          <StatusBadge label={getRarityLabel(item.rarity)} color={rarityColor} />
        </div>

        {/* Top-right status badges */}
        <div className="absolute right-2 top-2 flex flex-col items-end gap-1">
          {equipped && <StatusBadge label="EQUIPADO" color="#9d0de9" />}
          {!equipped && owned && (
            <StatusBadge label="POSSUIDO" color="rgba(200,254,78,0.85)" textColor="#0f0f12" />
          )}
          {incompatible && (
            <span className="flex items-center gap-1 rounded bg-[#e0566b]/85 px-1.5 py-0.5 text-[0.95rem] font-semibold uppercase tracking-wider text-[#0f0f12]">
              <ShieldX size={11} />
              Incompativel
            </span>
          )}
        </div>

        {/* Lock overlay for items that aren't purchasable AND aren't owned */}
        {!owned && !item.purchasable && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/40">
            <Lock size={36} className="text-white/40" />
          </div>
        )}
      </div>

      {/* Info */}
      <div className="flex flex-1 flex-col gap-2 px-3 py-3">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0 flex-1">
            <p className="truncate text-[1.3rem] font-semibold text-[#f8efff]">{item.name}</p>
            {item.subcategory && (
              <p className="truncate text-[1rem] uppercase tracking-wider text-white/40">
                {item.subcategory}
              </p>
            )}
          </div>

          {item.price != null && item.price > 0 && (
            <div className="flex shrink-0 items-center gap-1 rounded-md bg-white/[0.04] px-2 py-1 text-[1.1rem] font-semibold text-[#fedb4e]">
              <Coins size={13} />
              {item.price.toLocaleString('pt-BR')}
            </div>
          )}
        </div>

        <button
          type="button"
          disabled={actionDisabled}
          onClick={() => !actionDisabled && onAction?.(item, action)}
          className={cn(
            'mt-1 rounded-md px-3 py-2 text-[1.1rem] font-semibold uppercase tracking-wider transition-colors',
            actionDisabled
              ? 'cursor-not-allowed bg-white/[0.03] text-white/30'
              : action === 'buy'
              ? 'bg-[#fedb4e]/15 text-[#fedb4e] hover:bg-[#fedb4e]/25'
              : action === 'unequip'
              ? 'bg-[#e0566b]/15 text-[#e0566b] hover:bg-[#e0566b]/25'
              : 'bg-primary/15 text-primary hover:bg-primary/25',
          )}
        >
          {actionLabel[action]}
        </button>
      </div>
    </div>
  )
}
