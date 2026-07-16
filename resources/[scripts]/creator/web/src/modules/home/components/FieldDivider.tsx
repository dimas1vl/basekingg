export function FieldDivider() {
  return (
    <div className="overflow-hidden h-[17px] w-full relative">
      <div
        className="absolute flex h-[17px] items-center justify-center"
        style={{ right: '-979.5px', width: '1929.5px' }}
      >
        <img
          src={new URL('/divider.svg', import.meta.url).href}
          alt=""
          className="h-[17px] w-full"
          style={{ transform: 'rotate(180deg) scaleY(-1)' }}
        />
      </div>
    </div>
  )
}
