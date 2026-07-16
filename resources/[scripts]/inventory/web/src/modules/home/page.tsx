import { DndProvider } from 'react-dnd'
import { TouchBackend } from 'react-dnd-touch-backend'
import { debugData } from '@/utils/debugData'
import weaponImg from '@/assets/inventory/weapon-mk2.png'
import Inventory from './components/Inventory'
import type { InventoryItem } from './components/Inventory'

debugData<{ items: (InventoryItem | null)[] }>([
  {
    event: 'setInventory',
    data: {
      items: [
        { name: 'weapon_carbinerifle_mk2', label: 'M4A1', quantity: 1, image: weaponImg },
        null,
        { name: 'weapon_carbinerifle_mk2', label: 'KIT MEDICO', quantity: 3, image: weaponImg },
        { name: 'weapon_carbinerifle_mk2', label: 'MUNICAO', quantity: 2, image: weaponImg },
        null,
      ],
    },
  },
],1000)

export default function Home() {
  return (
    <DndProvider backend={TouchBackend} options={{ enableMouseEvents: true }}>
      <Inventory />
    </DndProvider>
  )
}
