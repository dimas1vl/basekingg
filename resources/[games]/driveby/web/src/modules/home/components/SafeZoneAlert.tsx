import { imgFriendsDivider } from '../assets'

interface SafeZoneAlertProps {
  title: string
  message: string
}

export default function SafeZoneAlert({ title, message }: SafeZoneAlertProps) {
  return (
    <div className="-translate-x-1/2 absolute content-stretch flex flex-col items-start left-1/2 top-[103px]">
      <div className="bg-[rgba(29,28,38,0.65)] content-stretch flex flex-col items-start pt-[6px] px-[6px] relative shrink-0 w-[410px]">
        <div className="content-stretch flex flex-col gap-[4px] items-start relative shrink-0 w-full">
          <div className="bg-[rgba(29,28,38,0.75)] border-[var(--color-primary,#c8fe4e)] border-l-[4px] border-r-[4px] border-solid content-stretch flex h-[26px] items-center justify-center pl-[16px] pr-[12px] relative shrink-0 w-full">
            <div className="[word-break:break-word] flex flex-col font-['Termina:Demi',sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[14px] text-[color:var(--color-primary,#c8fe4e)] text-center whitespace-nowrap">
              <p className="leading-[normal]">{title}</p>
            </div>
          </div>
          <div className="content-stretch flex items-start justify-center relative shrink-0 w-full">
            <div className="[word-break:break-word] flex flex-col font-['Termina:Medium',sans-serif] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--color-light,#f8efff)] text-center text-ellipsis whitespace-nowrap">
              <p className="leading-[normal] overflow-hidden text-ellipsis">
                {message}
              </p>
            </div>
          </div>
        </div>
      </div>
      <div className="h-[13px] relative shrink-0 w-[410px]">
        <img
          alt=""
          className="absolute block inset-0 max-w-none size-full"
          src={imgFriendsDivider}
        />
      </div>
    </div>
  )
}
