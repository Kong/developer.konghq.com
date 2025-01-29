/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "app/*.{html,md}",
    "app/_layouts/**/*.html",
    "app/_includes/**/*.{html,md}",
    "app/_landing_pages/**/*.yaml",
    "app/_gateway_entities/**",
    "app/_how-tos/**/*.md",
    "app/_plugins/**/*.rb",
    "app/_assets/javascripts/**",
    "app/gateway/**"
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
    "DocSearch-Commands",
  ],
  theme: {
    extend: {
      colors:{
        brand: 'rgb(var(--color-brand), <alpha-value>)',
        'brand-saturated': 'rgb(var(--color-brand-saturated), <alpha-value>)',
        'semantic-red-primary': 'rgb(var(--color-semantic-red-primary), <alpha-value>)',
        'semantic-red-secondary': 'rgb(var(--color-semantic-red-secondary), <alpha-value>)',
        'semantic-yellow-primary': 'rgb(var(--color-semantic-yellow-primary), <alpha-value>)',
        'semantic-yellow-secondary': 'rgb(var(--color-semantic-yellow-secondary), <alpha-value>)',
        'semantic-blue-primary': 'rgb(var(--color-semantic-blue-primary), <alpha-value>)',
        'semantic-blue-secondary': 'rgb(var(--color-semantic-blue-secondary), <alpha-value>)',
        'semantic-green-primary': 'rgb(var(--color-semantic-green-primary), <alpha-value>)',
        'semantic-green-secondary': 'rgb(var(--color-semantic-green-secondary), <alpha-value>)',
        'semantic-grey-primary': 'rgb(var(--color-semantic-grey-primary), <alpha-value>)',
        'semantic-grey-secondary': 'rgb(var(--color-semantic-grey-secondary), <alpha-value>)',
      },
      textColor: {
        primary: 'rgb(var(--color-text-primary), <alpha-value>)',
        secondary: 'rgb(var(--color-text-secondary), <alpha-value>)',
        terciary: 'rgb(var(--color-text-terciary), <alpha-value>)',
      },
      borderColor: {
        primary: 'rgb(var(--color-border-primary), <alpha-value>)',
      },
      backgroundColor: {
        primary: 'rgb(var(--color-bg-primary), <alpha-value>)',
        secondary: 'rgb(var(--color-bg-secondary), <alpha-value>)',
        'code-block': 'rgb(var(--color-bg-code-block), <alpha-value>)',
        'code-block-header': 'rgb(var(--color-bg-code-block-header), <alpha-value>)',
        'hover-component': 'rgb(var(--color-bg-hover-component), <alpha-value>)',
      },
      boxShadow: {
        primary: '0 4px 12px 0 rgb(var(--color-shadow-primary))',
        'hover-card': '0 4px 20px 0 rgb(var(--color-shadow-hover-cardp))'
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
};
