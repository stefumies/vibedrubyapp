# welcome-server

Minimal Ruby server with one page, app code under `lib/`, and a local SQLite database.

## Requirements

- Ruby
- Bundler
- Firefox LiveReload extension if you want automatic browser reloads

## Install

```sh
cd /home/stefumies/Development/Ruby/welcome-server
bundle install
```

## Run

Start once:

```sh
bundle exec ruby bin/server
```

Start with auto-reload for the Ruby app and browser page:

```sh
./bin/dev
```

`./bin/dev` starts:

- the Ruby app restarter
- a LiveReload server for the browser extension on `127.0.0.1:35729`

The executable entrypoint lives in `bin/server`, and the server implementation lives in `lib/welcome_server/app.rb`.

Stop the dev processes:

```sh
./bin/stop
```

## Open

Visit:

```text
http://localhost:4567
```

If you are using the Firefox LiveReload extension, connect it to:

```text
127.0.0.1:35729
```

## Test

From the project root, run:

```sh
ruby -Itest test/welcome_server/app_test.rb
```

## Behavior

- Enter a name in the `fullname` field and submit.
- First time: `Hello, NAME`
- Existing name: `Hello again, NAME`
- New names are added to the list above the form.
- Names can be edited inline.
- Each listed name has a delete button.
- The list becomes scrollable after it grows.
