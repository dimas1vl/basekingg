/**
 * Pure ability data — this is the shape the Lua backend sends via `getAbilities`.
 * Keep it free of any frontend-only/asset fields so the backend can drive it.
 */
export interface AbilityData {
  /** Stable id sent back to Lua when the player picks this ability. */
  id: string
  /** Bold title shown on the card (e.g. "REVIVE"). */
  title: string
  /** Sub-label under the title. Use "\n" to force a line break. */
  description: string
}

/** Frontend-owned visuals, resolved by ability id (bundled assets live here). */
export interface AbilityVisual {
  /** Bundled icon URL for the card artwork. */
  icon: string
  /** Icon render size inside the card (in rem to match the responsive scale). */
  iconWidth: string
  iconHeight: string
}

/** Full ability used by the UI = backend data + resolved frontend visuals. */
export type Ability = AbilityData & AbilityVisual
