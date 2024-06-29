/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "app/*.{html,md}",
    "app/_layouts/**/*.html",
    "app/_includes/**/*.{html,md}",
    "app/_landing_pagees/**/*.yaml",
    "app/_tutorials/**/*.md",
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
    extend: {},
  },
  plugins: [],
};
