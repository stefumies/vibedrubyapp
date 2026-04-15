require "cgi"
require "erb"
require "sqlite3"
require "webrick"
require_relative "../../db/setup"

module WelcomeServer
  class App
    APP_ROOT = File.expand_path("../..", __dir__)
    DB_PATH = File.join(APP_ROOT, "welcome.db")
    PORT = 4567
    TEMPLATE_PATH = File.join(APP_ROOT, "views", "index.html.erb")
    STYLESHEET_PATH = File.join(APP_ROOT, "views", "styles.css")

    def initialize(db: SQLite3::Database.new(DB_PATH))
      @db = db
    end

    def run
      WelcomeServer::DatabaseSetup.call(db)

      server = WEBrick::HTTPServer.new(Port: PORT)
      mount_routes(server)
      trap("INT") { server.shutdown }

      puts "Server running at http://localhost:#{PORT}"
      server.start
    end

    private

    attr_reader :db

    def names
      db.execute("SELECT fullname FROM users ORDER BY id DESC").flatten
    end

    def render_page(message = nil, editing_name = nil)
      ERB.new(File.read(TEMPLATE_PATH)).result_with_hash(
        names: names,
        message: message.to_s,
        editing_name: editing_name,
        escape_html: method(:escape_html)
      )
    end

    def render_stylesheet
      File.read(STYLESHEET_PATH)
    end

    def escape_html(value)
      CGI.escapeHTML(value.to_s)
    end

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

    def update_name(original_name, updated_name)
      old_name = original_name.to_s.strip
      new_name = updated_name.to_s.strip
      return nil if old_name.empty? || new_name.empty?

      sql_old_name = old_name.gsub("'", "''")
      sql_new_name = new_name.gsub("'", "''")
      db.execute("UPDATE users SET fullname = '#{sql_new_name}' WHERE fullname = '#{sql_old_name}'")
      "Updated #{new_name}"
    end

    def delete_name(fullname)
      name = fullname.to_s.strip
      return nil if name.empty?

      sql_name = name.gsub("'", "''")
      db.execute("DELETE FROM users WHERE fullname = '#{sql_name}'")
      nil
    end

    def respond(res, message = nil, editing_name = nil)
      res["Content-Type"] = "text/html; charset=utf-8"
      res["Cache-Control"] = "no-store"
      res["Pragma"] = "no-cache"
      res["Expires"] = "0"
      res.body = render_page(message, editing_name)
    end

    def respond_stylesheet(res)
      res["Content-Type"] = "text/css; charset=utf-8"
      res["Cache-Control"] = "no-store"
      res["Pragma"] = "no-cache"
      res["Expires"] = "0"
      res.body = render_stylesheet
    end

    def mount_routes(server)
      server.mount_proc "/styles.css" do |_req, res|
        respond_stylesheet(res)
      end

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
    end
  end
end
