import React, { type ComponentProps, type ReactNode } from 'react'

type IconProps = ComponentProps<'svg'> & {
	size?: number
	stroke?: number
	children: ReactNode
}

export function Icon({ children, size = 18, stroke = 1.6, ...rest }: IconProps) {
	return (
		<span style={{ display: 'inline-flex', alignItems: 'center' }}>
			{typeof children === 'function'
				? (children as unknown as (p: any) => JSX.Element)({ size, stroke, ...rest })
				: children}
		</span>
	)
}


