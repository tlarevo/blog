// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: ["./js/**/*.js", "../lib/blog_web.ex", "../lib/blog_web/**/*.*ex"],
  darkMode: "class",
  theme: {
    extend: {
      borderColor: ({ theme }) => ({
        primary: theme("colors.primary"),
      }),
      fontFamily: {
        sans: ["Roboto Mono", "monospace"],
        mono: ["IBM Plex Mono", "monospace"],
        heading: ["Fira Sans", "sans-serif"],
      },
      colors: {
        primary: "#ff0000",
        dark: {
          primary: "#50fa7b",
          bg: "#202124",
          text: "#ffffff",
        },
        border: {
          light: "#663399",
          dark: "#333333",
        },
      },
      typography: ({ theme }) => ({
        DEFAULT: {
          css: {
            a: {
              textDecoration: "none",
              borderBottom: "3px solid #ff0000",
              "&:hover": {
                backgroundColor: "#ff0000",
                color: "#ffffff",
              },
            },
            pre: {
              backgroundColor: "#ececec",
              borderRadius: 0,
              padding: "1em",
            },
            code: {
              backgroundColor: "#f1f1f1",
              padding: "0.1em 0.2em",
            },
          },
        },
        dark: {
          css: {
            a: {
              borderBottom: "3px solid #50fa7b",
              "&:hover": {
                backgroundColor: "#50fa7b",
                color: "#000000",
              },
            },
            pre: {
              backgroundColor: "#272822",
            },
            code: {
              backgroundColor: "#333333",
            },
          },
        },
      }),
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    // ... keep existing plugins
  ],
};
