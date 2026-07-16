import { SVGProps, useId } from 'react'

export function ArrowSwitchmodeIcon(props: SVGProps<SVGSVGElement>) {
  const id = useId()
  return (
    <svg width="303" height="56" viewBox="0 0 303 56" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <g filter={`url(#${id}-filter)`}>
        <path fillRule="evenodd" clipRule="evenodd" d="M28.5039 26.1085C68.2176 5.14941 117.611 -9.15398 160.362 13.5421C164.031 16.7522 167.374 20.1329 169.377 24.9757C170.587 27.5925 170.658 30.7221 169.886 33.5948C207.766 40.9702 245.376 53.9521 281.187 36.0704C287.954 32.1595 293.725 26.6349 298.001 20.0059C298.204 19.6927 298.407 19.3788 298.61 19.0655C299.239 19.4698 299.868 19.8742 300.496 20.2784C300.295 20.5931 300.094 20.908 299.894 21.2227C295.497 28.1609 289.474 34.0252 282.421 38.172C245.754 56.5301 206.099 44.3973 168.426 37.1309C167.84 38.1391 167.139 39.0519 166.339 39.8175C159.104 46.964 149.804 49.4332 140.876 51.462C131.837 53.3033 122.675 54.0725 113.385 53.3878C108.764 52.9802 104.074 52.3433 99.5459 50.2188C97.3187 49.0905 94.8017 47.4849 93.9102 44.253C93.1663 40.954 94.5999 38.4494 96.1455 36.3155C119.099 26.9733 142.322 28.5588 165.466 32.7628C166.92 27.5051 162.592 21.4393 157.277 17.1661C119.622 -2.86173 68.6723 10.4885 31.5752 31.045C26.4135 34.2914 21.4662 38.0569 17.4277 42.4249L30.7764 39.3917L32.1064 45.2432L7.10352 50.9249L2 25.4054L7.88281 24.2296L11.1416 40.5264C16.0825 34.6522 22.212 30.0083 28.5039 26.1085ZM163.503 36.212C140.94 32.1351 119.173 30.3781 99.2861 38.6534C92.9336 45.8019 105.853 48.8526 113.696 49.2735C122.472 49.8569 131.361 49.0491 139.976 47.2188C148.443 45.3067 157.392 42.4814 163.002 36.7257C163.178 36.5568 163.345 36.3847 163.503 36.212Z" fill={`url(#${id}-gradient)`} />
      </g>
      <defs>
        <filter id={`${id}-filter`} x="0" y="0" width="302.496" height="55.6349" filterUnits="userSpaceOnUse" colorInterpolationFilters="sRGB">
          <feFlood floodOpacity="0" result="BackgroundImageFix" />
          <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape" />
          <feTurbulence type="fractalNoise" baseFrequency="0.15151515603065491 0.15151515603065491" numOctaves={3} seed={525} />
          <feDisplacementMap in="shape" scale={4} xChannelSelector="R" yChannelSelector="G" result="displacedImage" width="100%" height="100%" />
          <feMerge result="effect1_texture_351_232">
            <feMergeNode in="displacedImage" />
          </feMerge>
          <feTurbulence type="fractalNoise" baseFrequency="2 2" stitchTiles="stitch" numOctaves={3} result="noise" seed={9784} />
          <feColorMatrix in="noise" type="luminanceToAlpha" result="alphaNoise" />
          <feComponentTransfer in="alphaNoise" result="coloredNoise1">
            <feFuncA type="discrete" tableValues="0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0" />
          </feComponentTransfer>
          <feComposite operator="in" in2="effect1_texture_351_232" in="coloredNoise1" result="noise1Clipped" />
          <feFlood floodColor="rgba(0, 0, 0, 0.56)" result="color1Flood" />
          <feComposite operator="in" in2="noise1Clipped" in="color1Flood" result="color1" />
          <feMerge result="effect2_noise_351_232">
            <feMergeNode in="effect1_texture_351_232" />
            <feMergeNode in="color1" />
          </feMerge>
        </filter>
        <linearGradient id={`${id}-gradient`} x1="2" y1="27.8174" x2="300.496" y2="27.8174" gradientUnits="userSpaceOnUse">
          <stop stopColor="white" />
          <stop offset="0.293269" stopColor="#C4E579" />
          <stop offset="1" stopColor="#C8FE4E" />
        </linearGradient>
      </defs>
    </svg>
  )
}
