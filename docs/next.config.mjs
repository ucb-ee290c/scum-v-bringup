import nextra from 'nextra'
import remarkMath from 'remark-math'
import rehypeKatex from 'rehype-katex'
import remarkGfm from 'remark-gfm'

const isProd = process.env.NODE_ENV === 'production'

const withNextra = nextra({
  theme: 'nextra-theme-docs',
  themeConfig: './theme.config.tsx',
  mdxOptions: {
    remarkPlugins: [remarkMath, remarkGfm],
    rehypePlugins: [rehypeKatex]
  },
  defaultShowCopyCode: true
})

export default withNextra({
  output: 'export',
  trailingSlash: true,
  basePath: isProd ? '/scum-v-bringup' : '',
  assetPrefix: isProd ? '/scum-v-bringup' : '',
  images: { unoptimized: true }
})