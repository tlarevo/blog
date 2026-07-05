// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// --- Theme toggle (light/dark), persisted to localStorage ---
const THEME_GLYPHS = {dark: "[ sun ]", light: "[ moon ]"}

function currentTheme() {
  const forced = document.documentElement.getAttribute("data-theme")
  if (forced === "dark" || forced === "light") return forced
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
}

function renderToggle() {
  const btn = document.getElementById("theme-toggle")
  if (!btn) return
  const isDark = currentTheme() === "dark"
  btn.textContent = isDark ? "[ sun ]" : "[ moon ]"
  btn.setAttribute("aria-pressed", String(isDark))
}

function toggleTheme() {
  const next = currentTheme() === "dark" ? "light" : "dark"
  document.documentElement.setAttribute("data-theme", next)
  try {
    localStorage.setItem("theme", next)
  } catch (e) {}
  renderToggle()
}

document.addEventListener("click", e => {
  if (e.target.closest("#theme-toggle")) toggleTheme()
})

// --- Active nav marker ---
function markActiveNav() {
  const path = window.location.pathname
  document.querySelectorAll("nav a").forEach(a => {
    const href = a.getAttribute("href")
    if (!href) return
    if (href === path || (path === "/" && href === "/") || (path === "/posts" && href === "/posts")) {
      a.setAttribute("aria-current", "page")
    } else {
      a.removeAttribute("aria-current")
    }
  })
}

// --- Reading progress bar (post pages only) ---
function updateReadingProgress() {
  const bar = document.getElementById("reading-progress")
  if (!bar) return
  const doc = document.documentElement
  const max = doc.scrollHeight - doc.clientHeight
  const ratio = max > 0 ? Math.min(doc.scrollTop / max, 1) : 0
  bar.style.inlineSize = (ratio * 100) + "%"
}

function initUi() {
  renderToggle()
  markActiveNav()
  updateReadingProgress()
}

window.addEventListener("scroll", updateReadingProgress, {passive: true})
window.addEventListener("DOMContentLoaded", initUi)
window.addEventListener("phx:page-loading-stop", initUi)

// --- Client-side post search ---
document.addEventListener("DOMContentLoaded", () => {
  const searchInput = document.getElementById("post-search")
  if (!searchInput) return

  searchInput.addEventListener("input", () => {
    const query = searchInput.value.trim().toLowerCase()
    const dataEl = document.getElementById("posts-data")
    const posts = dataEl ? JSON.parse(dataEl.textContent || "[]") : []

    document.querySelectorAll("ul.posts > li.post").forEach((li, i) => {
      if (!query) {
        li.style.display = ""
        return
      }
      const title = (posts[i] && posts[i].title || "").toLowerCase()
      li.style.display = title.includes(query) ? "" : "none"
    })
  })
})