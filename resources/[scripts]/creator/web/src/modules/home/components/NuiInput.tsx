type Props = {
  placeholder: string
  value: string
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
}

export function NuiInput({ placeholder, value, onChange }: Props) {
  return (
    <input
      type="text"
      placeholder={placeholder}
      value={value}
      onChange={onChange}
      className="border border-[rgba(248,239,255,0.25)] flex-1 h-[42px] px-[12px] bg-transparent text-[12px] text-[rgba(248,239,255,0.55)] outline-none min-w-0"
    />
  )
}
