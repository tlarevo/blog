# Blog touchpoints — real symbols reference

Reconnaissance record for later work. Line numbers refer to commit `3b7be342ee412530faa8b2ad3d1dc784918a799b`.

## 1. Index page

- Routes: `BlogWeb.Router` (`lib/blog_web/router.ex:21-23`)
  - `live "/", BlogLive.Index, :index`
  - `live "/posts", BlogLive.Index, :index`
  - `live "/posts/:number", BlogLive.Show, :show` (post detail)
- LiveView: `BlogWeb.BlogLive.Index` (`lib/blog_web/live/blog_live/index.ex`)
  - `mount/3` (line 7) — delegates to `load_posts/1`
  - `handle_params/3` (line 12) — `apply_action/3` sets `:page_title`
  - `apply_action(socket, :index, _params)` (line 36) — assigns `page_title: "Blog Posts"`
  - `blog_source/0` (line 80) — `Application.get_env(:blog, :blog_source, Blog)`; tests swap in
    `Blog.TestSource`
- Template: `lib/blog_web/live/blog_live/index.html.heex`
- Detail view: `BlogWeb.BlogLive.Show` (`lib/blog_web/live/blog_live/show.ex`), `mount/3` (line 5),
  `load_post/2`, `blog_source/0` (line 39)

## 2. Post list (listing/fetching)

- Fetch entry point: `Blog.fetch_posts/3` (`lib/blog.ex:20`)
  - Signature: `fetch_posts(count \\ 10, attr \\ [:id, :number, :title, :createdAt], after_cursor \\ nil)`
  - Returns `{:ok, %{posts: [map()], has_next_page: boolean(), end_cursor: String.t() | nil}} | {:error, term()}`
- GraphQL build/query: `Blog.do_fetch_posts/3` (`lib/blog.ex`) — `repository(owner: "tlarevo", name: "blog").discussions(first: count, orderBy: [field: :CREATED_AT, direction: :DESC], after: cursor)`, selected fields from `attr`, plus `pageInfo: [:hasNextPage, :endCursor]`
- Response shaping: `Blog.process_data/2` `:posts` clause (`lib/blog.ex`) — maps GitHub payload to
  `%{posts:, has_next_page:, end_cursor:}`
- HTTP + retry: `Blog.run_query_with_retry/3` (`@max_retries 3`, `@base_retry_delay_ms 200`,
  exponential backoff), `Blog.run_query/2` (Req + AbsintheClient + Cognac query builder),
  `Blog.handle_response/1`, `Blog.github_token/0`
- Single post: `Blog.fetch_post/1` (`lib/blog.ex:40`) → `Blog.do_fetch_post/1` → `process_data/2`
  `:post` clause
- List render: `index.html.heex` — `for post <- @posts` renders `post["number"]`, `post["title"]`,
  `post["createdAt"]` (formatted via `BlogWeb.BlogLive.Helpers.format_date/1`,
  `lib/blog_web/live/blog_live/helpers.ex`)
- Data loaded into socket: `BlogWeb.BlogLive.Index.load_posts/1` (`index.ex:40`) — assigns
  `:posts`, `:has_next_page`, `:end_cursor`, `:load_error`, `:page_title`
- Test double: `Blog.TestSource.fetch_posts/3` and `fetch_post/1`
  (`test/support/blog_test_source.ex`)

## 3. "Blog" label

- The "Blog" label is static markup, not fetched data:
  - Header brand link: `lib/blog_web/components/layouts/app.html.heex:3` —
    `<.link navigate={~p"/"} class="main">Blog</.link>`
  - Document title suffix: `lib/blog_web/components/layouts/root.html.heex:7-8` —
    `<.live_title suffix=" · Blog">`
- There is currently **no** GitHub label fetching anywhere in the codebase (no `labels` /
  `categories` selection in the GraphQL queries built by `Blog.do_fetch_posts/3` or
  `Blog.do_fetch_post/1`; the only `label` symbols are the form-label helpers
  `BlogWeb.CoreComponents.label/1` and the `:label` attr on `input/1` / table `:col` slot).
- If later work adds fetching of discussion labels (e.g. a "Blog" label filter), the real
  touchpoints are:
  - extend the `attr` list / query in `Blog.do_fetch_posts/3` (field selection is already
    parameterized via `fetch_posts/3`'s `attr` argument),
  - extend `Blog.process_data/2` `:posts` clause to carry label nodes,
  - extend `Blog.TestSource.fetch_posts/3` to mirror the new shape,
  - extend `load_posts/1` assigns and `index.html.heex` render loop.
  - Note the cache key `{:posts, count, attr, after_cursor}` already varies by `attr`.

## 4. "Load more" pagination

- Button: `index.html.heex` — `<button class="load-more" phx-click="load-more" phx-disable-with="Loading…">Load more</button>`, rendered when `@has_next_page`
- Event handler: `BlogWeb.BlogLive.Index.handle_event("load-more", _params, socket)`
  (`index.ex:17`) — reads `:end_cursor` from assigns, calls
  `blog_source().fetch_posts(@default_count, [:id, :number, :title, :createdAt], cursor)`,
  appends `new_posts`, updates `:has_next_page` / `:end_cursor`; errors assign
  `:load_error` (`:load_more_failed` / `:unexpected_response`)
- Page size: `@default_count 10` (`index.ex:4`)
- Cursor plumbing: `after_cursor` arg of `Blog.fetch_posts/3` → `after:` argument in
  `Blog.do_fetch_posts/3` GraphQL query; `end_cursor` from `pageInfo.endCursor` via
  `process_data/2`

## 5. ETS cache

- Module: `Blog.Cache` (`lib/blog/cache.ex`) — GenServer owning named public ETS table
  `:blog_cache` (`@table`, line 5), `@ttl_ms :timer.minutes(5)` (line 6)
- API: `Blog.Cache.get/1` (line 12) — lookup + TTL expiry check + delete-on-expiry, returns
  `nil` when missing/expired/table absent; `Blog.Cache.put/2` (line 31) — insert with
  `expires_at = System.monotonic_time(:millisecond) + @ttl_ms`; `start_link/1` (line 10);
  `init/1` (line 43) creates the table (`:named_table, :public, read_concurrency: true`)
- Call sites: `Blog.fetch_posts/3` (key `{:posts, count, attr, after_cursor}`, line 21) and
  `Blog.fetch_post/1` (key `{:post, number}`, line 41) — both read via `Blog.Cache.get/1`,
  write only successful `{:ok, _}` results via `Blog.Cache.put/2`
- Supervision: `Blog.Application.start/2` (`lib/blog/application.ex:14`) — `Blog.Cache` in the
  child list
- Tests: `Blog.CacheTest` (`test/blog/cache_test.exs`) — touches the raw table directly
  (`:ets.insert(:blog_cache, ...)`, `:ets.delete(:blog_cache)`)
