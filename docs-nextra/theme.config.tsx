import React from 'react'
import { DocsThemeConfig } from 'nextra-theme-docs'

const config: DocsThemeConfig = {
  docsRepositoryBase: 'https://github.com/ucb-ee290c/scum-v-bringup/tree/main/docs-nextra',
  logo: (
    <span style={{ 
      fontWeight: 600, 
      color: '#003262', 
      fontSize: '1.25rem',
      letterSpacing: '-0.025em'
    }}>
      SCuM-V <span style={{ 
        opacity: 0.7, 
        fontWeight: 500,
        color: '#46535E'
      }}>Documentation</span>
    </span>
  ),
  faviconGlyph: '📟',
  project: {
    link: 'https://github.com/ucb-ee290c/scum-v-bringup'
  },
  chat: {
    link: 'https://github.com/ucb-ee290c/scum-v-bringup/issues'
  },
  search: {
    placeholder: 'Search documentation…'
  },
  editLink: {
    content: 'Edit this page on GitHub →'
  },
  feedback: {
    content: 'Question? Give us feedback →',
    labels: 'feedback',
    useLink: () => 'https://github.com/ucb-ee290c/scum-v-bringup/issues/new?labels=feedback'
  },
  color: {
    hue: { light: 215, dark: 215 },
    saturation: { light: 100, dark: 80 },
    lightness: { light: 40, dark: 60 }
  },
  sidebar: {
    defaultMenuCollapseLevel: 1,
    toggleButton: true
  },
  footer: {
    content: (
      <div className="site-footer-text">
        Single-Chip Micro Mote V (SCμM-V) Documentation. {" "}
        © {new Date().getFullYear()} UC Berkeley EECS Department. All rights reserved.
      </div>
    )
  }
}

export default config