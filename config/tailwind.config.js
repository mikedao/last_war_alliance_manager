// config/tailwind.config.js
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  // This safelist ensures that common spacing classes are never removed.
  safelist: [
    {
      pattern: /^(m|p|gap|space)-(x|y)-[0-9]+$/,
    },
    {
      pattern: /^(m|p|gap|space)-[0-9]+$/,
    },
    {
      pattern: /^(w|h)-[0-9]+$/,
    },
  ],

  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
