# tlarevo.me

A personal blog powered by GitHub Discussions as a headless CMS.

**Live:** [tlarevo.me](https://tlarevo.me)

## Stack

- **Elixir** / **Phoenix 1.8** / **LiveView 1.1**
- **Tailwind CSS v4** with retro pixel-art styling (Press Start 2P, Pixelify Sans, Silkscreen)
- **MDEx** for fast Markdown-to-HTML rendering with syntax highlighting (GitHub Light / Dracula themes)

## Architecture

```
GitHub Discussions (CMS)
  │  GraphQL API
  ▼
Blog module ──▶ ETS cache (5 min TTL)
  │
  ▼
Phoenix LiveView (index + post pages)
```

Posts live as GitHub Discussions in a single repository. The `Blog` module fetches them via the GitHub GraphQL API and caches results in ETS. The index page uses cursor-based pagination with a "Load more" button.

## Features

- Dark / light theme toggle (persisted to `localStorage`, respects `prefers-color-scheme`)
- Retro pixel-art design with dashed borders and block shadows
- Client-side post search
- Reading time estimation
- Reading progress bar on post pages
- Atom RSS feed (`/feed.xml`)
- XML sitemap (`/sitemap.xml`)
- SEO: Open Graph tags, Twitter cards, JSON-LD (`BlogPosting` schema)
- `www` → apex 301 redirect
- Health check endpoint (`/health`)

## Local Development

```bash
mix setup       # install deps, setup Tailwind + esbuild, build assets
mix phx.server  # start at localhost:4000
```

Or run inside IEx:

```bash
iex -S mix phx.server
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GITHUB_TOKEN` | **Yes** | GitHub personal access token with `repo` scope (needed for the Discussions GraphQL API) |

## Deploy

```bash
fly deploy
```

Requires the [Fly CLI](https://fly.io/docs/hands-on/install-flyctl/) and an authenticated session. The app is configured for the `cdg` region.

## Testing

```bash
mix test
```
