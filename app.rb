require "cgi"
require "sqlite3"
require "webrick"

DB_PATH = File.expand_path("welcome.db", __dir__)
PORT = 4567

# Returns the shared SQLite connection for the app process.
def db
  @db ||= SQLite3::Database.new(DB_PATH)
end

# Creates the users table if it does not already exist.
def setup_db
  db.execute <<~SQL
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fullname TEXT NOT NULL UNIQUE
    )
  SQL
end

# Returns the stored names ordered from newest to oldest.
def names
  db.execute("SELECT fullname FROM users ORDER BY id DESC").flatten
end

# Renders the full HTML response for the page.
def html(message = nil, editing_name = nil)
  safe_message = message ? CGI.escapeHTML(message) : ""
  items = names.map do |name|
    safe_name = CGI.escapeHTML(name)
    if name == editing_name
      <<~HTML
        <li class="name-row">
          <form class="edit-form" method="post" action="/">
            <input type="hidden" name="original_name" value="#{safe_name}">
            <input class="edit-input" type="text" name="updated_name" value="#{safe_name}">
            <button class="icon-button save-button" type="submit" title="Save">&#10003;</button>
          </form>
        </li>
      HTML
    else
      <<~HTML
        <li class="name-row">
          <span class="name-text">#{safe_name}</span>
          <div class="row-actions">
            <form method="post" action="/">
              <input type="hidden" name="edit_name" value="#{safe_name}">
              <button class="icon-button edit-button" type="submit" title="Edit">&#9998;</button>
            </form>
            <form method="post" action="/">
              <input type="hidden" name="delete_name" value="#{safe_name}">
              <button class="icon-button delete-button" type="submit" title="Delete">Delete</button>
            </form>
          </div>
        </li>
      HTML
    end
  end.join

  <<~HTML
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome</title>
        <style>
          body {
            margin: 0;
            min-height: 100vh;
            padding: 24px 16px;
            box-sizing: border-box;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: sans-serif;
            background: #f4f4f4;
          }

          .app {
            width: min(360px, 100%);
            display: grid;
            gap: 12px;
            padding: 16px;
            border: 1px solid #ccc;
            border-radius: 16px;
            background: #fff;
            box-shadow: 0 10px 24px rgba(0, 0, 0, 0.12);
            box-sizing: border-box;
          }

          .add-form {
            display: grid;
            gap: 12px;
          }

          ul {
            margin: 0;
            padding: 0;
            list-style: none;
            max-height: 401px;
            overflow-y: auto;
            border: 1px solid #d7deea;
            background: #f6f9ff;
          }

          .name-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: nowrap;
            gap: 12px;
            padding: 10px 12px;
            border-bottom: 1px solid #e4ebf5;
            border-left: 4px solid #6ea8fe;
            background: #ffffff;
          }

          .name-row:last-child {
            border-bottom: 0;
          }

          .name-text {
            flex: 1;
            min-width: 0;
            overflow-wrap: anywhere;
            text-align: left;
          }

          .row-actions,
          .edit-form {
            display: flex;
            align-items: center;
            gap: 8px;
          }

          .edit-form {
            flex: 1 1 auto;
            min-width: 0;
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
          }

          .row-actions form,
          .name-row > form {
            width: auto;
            display: block;
          }

          input,
          button {
            width: 100%;
            padding: 12px;
            font-size: 16px;
            box-sizing: border-box;
          }

          button {
            border: 1px solid #cbd5e1;
            background: #eef4ff;
          }

          .icon-button {
            width: auto;
            min-width: 44px;
            padding: 10px 12px;
          }

          .edit-input {
            width: auto;
            min-width: 0;
            text-align: left;
          }

          .name-row .icon-button,
          .row-actions form,
          .name-row > form {
            flex-shrink: 0;
          }

          p {
            min-height: 24px;
            margin: 0;
            text-align: center;
          }

          .edit-button {
            background: #eef4ff;
            border-color: #c6d7ff;
          }

          .save-button {
            background: #ecfdf3;
            border-color: #b7ebc8;
          }

          .delete-button {
            border-color: #f2c6cc;
            background: #fff1f3;
          }

          .add-form button {
            background: #dcfce7;
            border-color: #86efac;
          }

          @media (max-width: 480px) {
            .name-row {
              align-items: stretch;
              flex-direction: column;
            }

            .row-actions,
            .edit-form {
              width: 100%;
            }

            .name-row form,
            .name-row button,
            .edit-input {
              width: 100%;
            }
          }
        </style>
      </head>
      <body>
        <div class="app">
          <ul>#{items}</ul>
          <form class="add-form" method="post" action="/">
            <input type="text" name="fullname" placeholder="fullname" value="">
            <button type="submit">Submit</button>
          </form>
          <p id="message">#{safe_message}</p>
        </div>
        <script>
          const addForm = document.querySelector(".add-form");
          const message = document.getElementById("message");

          addForm?.addEventListener("submit", () => {
            message.textContent = "";
          });
        </script>
      </body>
    </html>
  HTML
end

# Looks up a name and creates it when it does not already exist.
def find_or_create_message(fullname)
  name = fullname.to_s.strip
  return nil if name.empty?

  sql_name = name.gsub("'", "''")
  found = db.get_first_value("SELECT 1 FROM users WHERE fullname = '#{sql_name}'")

  if found
    "Hello again, #{name}"
  else
    db.execute("INSERT INTO users(fullname) VALUES ('#{sql_name}')")
    "Hello, #{name}"
  end
end

# Updates an existing stored name.
def update_name(original_name, updated_name)
  old_name = original_name.to_s.strip
  new_name = updated_name.to_s.strip
  return nil if old_name.empty? || new_name.empty?

  sql_old_name = old_name.gsub("'", "''")
  sql_new_name = new_name.gsub("'", "''")
  db.execute("UPDATE users SET fullname = '#{sql_new_name}' WHERE fullname = '#{sql_old_name}'")
  "Updated #{new_name}"
end

# Deletes a stored name.
def delete_name(fullname)
  name = fullname.to_s.strip
  return nil if name.empty?

  sql_name = name.gsub("'", "''")
  db.execute("DELETE FROM users WHERE fullname = '#{sql_name}'")
  nil
end

# Writes the HTML response and disables browser caching in development.
def respond(res, message = nil, editing_name = nil)
  res["Content-Type"] = "text/html; charset=utf-8"
  res["Cache-Control"] = "no-store"
  res["Pragma"] = "no-cache"
  res["Expires"] = "0"
  res.body = html(message, editing_name)
end

setup_db

server = WEBrick::HTTPServer.new(Port: PORT)

server.mount_proc "/" do |req, res|
  if req.request_method == "POST"
    if req.query["delete_name"]
      delete_name(req.query["delete_name"])
      respond(res)
    elsif req.query["edit_name"]
      respond(res, nil, req.query["edit_name"])
    elsif req.query["original_name"]
      respond(res, update_name(req.query["original_name"], req.query["updated_name"]))
    else
      fullname = req.query["fullname"]
      respond(res, find_or_create_message(fullname))
    end
  else
    respond(res)
  end
end

trap("INT") { server.shutdown }

puts "Server running at http://localhost:#{PORT}"
server.start
