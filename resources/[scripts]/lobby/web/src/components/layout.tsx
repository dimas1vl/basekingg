import { useEffect } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { NavbarMenuBtn } from '@/components/ui'
import { CoinIcon, ConfigIcon, KinggPointsIcon, UsersIcon } from '@/components/icons'
import { NAVBAR_ITEMS } from '@/config/navbar'
import { useLobby } from '@/providers/LobbyProvider'
import { fetchData } from '@/utils/fetchData'

const fmt = (n: number) => n.toLocaleString('pt-BR')

const VIEW_BY_PATH: Record<string, string> = {
  '/': 'home',
  '/custom': 'custom',
}

export default function Layout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { player, squad, online } = useLobby()

  const isHome = location.pathname === '/'
  const isCustom = location.pathname === '/custom'
  const showWorldBackground = isHome || isCustom

  const layoutBackground = isCustom
    ? {
        backgroundImage: `url(${new URL('/bg-middle.png', import.meta.url).href})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        backgroundRepeat: 'no-repeat',
      }
    : !showWorldBackground
      ? {
          backgroundImage: `url(${new URL('/background-full.png', import.meta.url).href})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
        }
      : undefined

  useEffect(() => {
    const view = VIEW_BY_PATH[location.pathname] ?? 'home'
    fetchData('setLobbyView', { view })
  }, [location.pathname])
  const leader = squad.find((m) => m.isLeader)
  const members = squad.filter((m) => !m.isLeader)
  const emptySlots = Math.max(0, 4 - members.length)

  return (
    <div className="flex flex-col w-full h-full" style={layoutBackground}>
      <div
        className="relative w-full h-[6rem] flex items-center px-[5.2rem] overflow-hidden"
        style={{
          backgroundImage: `url(${new URL('/navbar-menu.png', import.meta.url).href})`,
          backgroundSize: '100% 100%',
          backgroundPosition: 'center',
        }}
      >
        <div className="shrink-0 w-[21.6rem]">
          <img src={new URL('/logo.png', import.meta.url).href} alt="" />
        </div>

        <nav className="flex flex-1 items-center justify-center">
          {NAVBAR_ITEMS.map((item) => {
            const isActive = location.pathname === item.path
            return (
              <NavbarMenuBtn
                key={item.path}
                label={item.label}
                state={isActive ? 'active' : 'default'}
                gold={item.gold}
                onClick={() => navigate(item.path)}
              />
            )
          })}
        </nav>

        <div className="shrink-0 w-[21.6rem] flex items-center justify-end gap-[1.2rem]">
          <div className="flex items-center gap-[0.8rem]">
            <span className="font-['Termina',sans-serif] text-[1.4rem] font-medium text-[#f8efff] whitespace-nowrap">
              {fmt(player?.coins ?? 0)}
            </span>
            <CoinIcon width={24} height={24} className="text-[#f8efff]" />
          </div>

          <svg width="8" height="24" viewBox="0 0 8 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path
              opacity="0.25"
              fillRule="evenodd"
              clipRule="evenodd"
              d="M7.01856 0.539477L6.23327 1.15674C6.25847 1.26441 6.32365 1.53418 6.36178 1.69154L7.54581 1.33937L8 4.03726L7.02012 5.12389L6.47216 6.56944L5.76047 10.379L5.15206 13.1316C5.10082 14.3746 4.82219 15.6277 4.3908 16.4838L3.38233 18.6434L2.68006 21.6587L2.68655 21.6578L2.71395 23.1353L1.52539 24L0 20.7003L0.939018 18.2944L0.598886 16.4888L1.4214 14.9334C1.79435 14.4764 2.2858 13.5136 2.15273 13.4163L1.80477 11.0688L2.7465 9.02256L3.35535 8.26763C3.3626 7.38528 3.42317 6.18286 3.51152 5.25824L4.64908 3.80603L5.09237 1.98341C5.20789 1.37846 5.63713 0.485914 5.99162 0L7.01856 0.539477ZM4.59645 10.0562L5.20248 9.67701L4.38534 8.90601L4.59645 10.0562Z"
              fill="#F8EFFF"
            />
          </svg>

          <div className="flex items-center gap-[0.8rem]">
            <span className="font-['Termina',sans-serif] text-[1.4rem] font-medium text-[#fedb4e] whitespace-nowrap">
              {fmt(player?.points ?? 0)}
            </span>
            <KinggPointsIcon width={24} height={24} className="text-[#fedb4e]" />
          </div>
        </div>
      </div>

      <div
        className="w-full h-[2.3rem] relative bottom-[.4rem]"
        style={{
          backgroundImage: `url(${new URL('/navbar-divider.png', import.meta.url).href})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
        }}
      />

      <main className="flex-1 min-h-0 overflow-hidden">
        <Outlet />
      </main>

      <div
        className="relative w-full h-[7rem] flex flex-col justify-end"
        style={{
          backgroundImage: `url(${new URL('/footer.png', import.meta.url).href})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
        }}
      >
        <div className="flex items-center justify-end gap-[1.5rem] px-[5.2rem] h-[6rem]">
          <div className="flex items-center gap-[0.6rem]">
            {leader && (
              <div className="relative">
                <img
                  src={new URL('/crown.png', import.meta.url).href}
                  alt=""
                  className="absolute pointer-events-none"
                  style={{
                    width: '8.3rem',
                    top: '-2.2rem',
                    left: '40%',
                    transform: 'translateX(-50%)',
                    filter: 'drop-shadow(0 0 0.8rem #fbd992)',
                  }}
                />
                <div className="size-[4.2rem] rounded-full border-2 border-[#c8fe4e] overflow-hidden">
                  <img src={leader.avatar} alt="" className="size-full object-cover" />
                </div>
              </div>
            )}

            <svg width="9" height="14" viewBox="12 2 7 10" fill="none" className="rotate-[-5deg] shrink-0">
              <path
                d="M18.8219 2.91532L18.8434 3.94795L18.9428 4.83325L18.8595 5.5208L18.3184 6.40871L18.4099 7.45728L16.9937 8.52465L16.0699 9.84881L15.3566 10.9293L15.4023 11.8148C14.4707 12.4381 13.7168 12.39 12.9333 11.732L12.8174 11.0473L13.5284 8.74408C13.9295 8.53275 14.188 8.02439 13.9646 7.81307L13.8002 6.66027L15.187 5.45105L16.8319 3.94795L17.1469 2.93674L18.0275 2.42317L18.8219 2.91532Z"
                fill="#f8efff20"
              />
            </svg>

            <div className="flex items-center gap-[0.4rem]">
              {members.map((m) => (
                <div key={m.id} className="size-[4.2rem] rounded-full border-2 border-[#f8efff] overflow-hidden">
                  <img src={m.avatar} alt="" className="size-full object-cover" />
                </div>
              ))}
              {Array.from({ length: emptySlots }).map((_, i) => (
                <button
                  key={`invite-${i}`}
                  className="size-[4.2rem] rounded-full border-2 border-[rgba(248,239,255,0.3)] flex items-center justify-center cursor-pointer"
                  onClick={() => fetchData('inviteToSquad')}
                >
                  <Plus size={16} className="text-[rgba(248,239,255,0.4)]" />
                </button>
              ))}
            </div>
          </div>

          <div className="flex items-center gap-[0.6rem]">
            <button
              className="flex items-center gap-[1rem] h-[4.2rem] pl-[1.8rem] pr-[1.2rem] border-solid border-t-2 border-r-2 border-b-2 border-l-8 border-[rgba(248,239,255,0.15)] cursor-pointer"
              onClick={() => fetchData('openActivity')}
            >
              <UsersIcon width={22} height={18} className="text-[#f8efff] shrink-0" />
              <span className="font-['Termina',sans-serif] text-[1.6rem] font-medium text-[#f8efff]">
                {online}
              </span>
            </button>
            <button
              className="size-[4.2rem] bg-[rgba(248,239,255,0.15)] flex items-center justify-center cursor-pointer"
              onClick={() => fetchData('openSettings')}
            >
              <ConfigIcon width={21} height={20} className="text-[#f8efff]" />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
