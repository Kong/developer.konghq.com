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
        brand: 'rgb(var(--color-brand), 1)',
        'brand-saturated': 'rgb(var(--color-brand-saturated), 1)'
      },
      textColor: {
        primary: 'rgb(var(--color-text-primary), 1)',
        secondary: 'rgb(var(--color-text-secondary), 1)',
        terciary: 'rgb(var(--color-text-terciary), 1)',
      },
      borderColor: {
        primary: 'rgb(var(--color-border-primary), .05)'
      },
      backgroundColor: {
        primary: 'rgb(var(--color-bg-primary), 1)',
        secondary: 'rgb(var(--color-bg-secondary), 1)',
        'code-block': 'rgb(var(--color-bg-code-blcock), 1)'
      },
      boxShadow: {
        primary: '0 4px 12px 0 rgb(var(--color-shadow-primary), 0.04)'
      }
    },
  },
  plugins: [],
};
