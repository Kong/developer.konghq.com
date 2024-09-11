/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "app/*.{html,md}",
    "app/_layouts/**/*.html",
    "app/_includes/**/*.{html,md}",
    "app/_landing_pagees/**/*.yaml",
    "app/_how-tos/**/*.md",
    "app/_plugins/**/*.rb",
    "app/_assets/javascripts/**"
  ],
  darkMode: 'selector',
  safelist: [
    {
      pattern: /grid-cols-[1-6]/,
      variants: ["md", "lg"],
    },
    "self-start",
    "self-center",
    "self-end",
  ],
  theme: {
    extend: {
      colors:{
        brand: 'rgb(var(--color-brand), <alpha-value>)',
        'brand-saturated': 'rgb(var(--color-brand-saturated), <alpha-value>)'
      },
      textColor: {
        primary: 'rgb(var(--color-text-primary), <alpha-value>)',
        secondary: 'rgb(var(--color-text-secondary), <alpha-value>)',
        terciary: 'rgb(var(--color-text-terciary), <alpha-value>)',
        'semantic-red-primary': 'rgb(var(--color-semantic-red-primary), <alpha-value>)',
      },
      borderColor: {
        primary: 'rgb(var(--color-border-primary), <alpha-value>)',
        brand: 'rgb(var(--color-brand), <alpha-value>)'
      },
      backgroundColor: {
        primary: 'rgb(var(--color-bg-primary), <alpha-value>)',
        secondary: 'rgb(var(--color-bg-secondary), <alpha-value>)',
        'code-block': 'rgb(var(--color-bg-code-block), <alpha-value>)',
      },
      boxShadow: {
        primary: '0 4px 12px 0 rgb(var(--color-shadow-primary))'
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
};
