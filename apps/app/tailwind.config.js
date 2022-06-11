const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
    content: [
      "./components/**/*.{js,vue,ts}",
      "./layouts/**/*.vue",
      "./pages/**/*.vue",
      "./plugins/**/*.{js,ts}",
      "../../node_modules/ui/dist/**/*.js"
    ],
    theme: {
      extend: {
        fontFamily: {
          sans: ['Inter var', ...defaultTheme.fontFamily.sans],
          mono: ['Fira Code VF', ...defaultTheme.fontFamily.mono],
          source: ['Source Sans Pro', ...defaultTheme.fontFamily.sans],
          'ubuntu-mono': ['Ubuntu Mono', ...defaultTheme.fontFamily.mono],
        },
        height: {
          'screen-no-header': 'calc(100vh - 120px)',
        }
      },
    },
    plugins: [],
}
