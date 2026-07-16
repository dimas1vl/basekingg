import { useEffect, useState } from 'react'

type NewsItem = {
  image: string
  title: string
  date: string
  description: string
}

type NewsSliderProps = {
  items: NewsItem[]
  interval?: number
}

function Slash({ active, onClick }: { active: boolean; onClick: () => void }) {
  return (
    <button onClick={onClick} className="cursor-pointer">
      <svg width="9" height="14" viewBox="12 2 7 10" fill="none">
        <path
          d="M18.8219 2.91532L18.8434 3.94795L18.9428 4.83325L18.8595 5.5208L18.3184 6.40871L18.4099 7.45728L16.9937 8.52465L16.0699 9.84881L15.3566 10.9293L15.4023 11.8148C14.4707 12.4381 13.7168 12.39 12.9333 11.732L12.8174 11.0473L13.5284 8.74408C13.9295 8.53275 14.188 8.02439 13.9646 7.81307L13.8002 6.66027L15.187 5.45105L16.8319 3.94795L17.1469 2.93674L18.0275 2.42317L18.8219 2.91532Z"
          fill={active ? '#c8fe4e' : 'rgba(248,239,255,0.4)'}
          style={{ transition: 'fill 0.3s' }}
        />
      </svg>
    </button>
  )
}

export function NewsSlider({ items, interval = 4000 }: NewsSliderProps) {
  const [current, setCurrent] = useState(0)
  const item = items[current]

  useEffect(() => {
    if (items.length <= 1) return
    const timer = setInterval(() => {
      setCurrent((prev) => (prev + 1) % items.length)
    }, interval)
    return () => clearInterval(timer)
  }, [items.length, interval])

  if (!item) return null

  return (
    <div className="bg-[rgba(29,28,38,0.95)] p-[0.6rem]">
      <div className="relative h-[12.7rem] overflow-hidden">
        {items.map((s, i) => (
          <div
            key={i}
            className="absolute inset-0 transition-transform duration-500 ease-in-out"
            style={{ transform: `translateX(${(i - current) * 100}%)` }}
          >
            <img src={s.image} alt="" className="size-full object-cover pointer-events-none" />
          </div>
        ))}

        {/* Banner sobreposto na parte inferior da imagem */}
        <div className="absolute bottom-0 left-0 right-0 pointer-events-none">
          <img src={new URL('/footer-banner-newslatter.png', import.meta.url).href} alt="" className="w-full" />
        </div>

        {/* Slashes indicadores sobre o banner */}
        {items.length > 1 && (
          <div className="absolute bottom-0 left-0 right-0 h-[3.4rem] flex items-center justify-end pr-[1.2rem]">
            <div className="flex items-center gap-[0.4rem]">
              {items.map((_, i) => (
                <Slash key={i} active={i === current} onClick={() => setCurrent(i)} />
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="flex flex-col gap-[0.4rem]">
        <div className="flex h-[2.6rem] items-center justify-between bg-[rgba(248,239,255,0.05)] border-l-8 border-solid border-[#f8efff] pl-[1.6rem] pr-[1.2rem]">
          <span className="text-[1.4rem] font-semibold text-[#f8efff] whitespace-nowrap">
            {item.title}
          </span>
          <span className="text-[1.2rem] text-[#f8efff] opacity-55 whitespace-nowrap">
            {item.date}
          </span>
        </div>

        <div className="px-[1.8rem] pb-[0.6rem]">
          <p className="text-[1.2rem] text-[#f8efff] opacity-55 text-justify leading-relaxed line-clamp-4">
            {item.description}
          </p>
        </div>
      </div>

    </div>
  )
}
