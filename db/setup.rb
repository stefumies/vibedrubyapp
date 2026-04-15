require "sqlite3"

module WelcomeServer
  module DatabaseSetup
    module_function

    def call(db)
      db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fullname TEXT NOT NULL UNIQUE
        )
      SQL
    end

    def setup_file(path)
      db = SQLite3::Database.new(path)
      call(db)
    ensure
      db&.close
    end
  end
end
