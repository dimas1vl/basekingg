type Props = { label: string; children: React.ReactNode }

export function FieldCard({ label, children }: Props) {
  return (
    <div className="border-2 border-[#4d4c55] flex flex-col w-full p-[2px]">
      <div className="bg-[rgba(29,28,38,0.85)] flex items-center justify-between h-[34px] px-[18px] py-[8px]">
        <span className="text-[#c8fe4e] text-[14px] font-bold uppercase tracking-wider">{label}</span>
        <img src={new URL('/ornament.svg', import.meta.url).href} alt="" className="w-[30px] h-[12px] object-contain" />
      </div>
      <div className="bg-[rgba(29,28,38,0.55)] p-[8px]">{children}</div>
    </div>
  )
}
