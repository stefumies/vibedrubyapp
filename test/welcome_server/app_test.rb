require "test_helper"
require_relative "../../db/setup"

module WelcomeServer
  class AppTest < TestHelper::TestCase
    def setup
      @db = SQLite3::Database.new(":memory:")
      @app = App.new(db: @db)
      WelcomeServer::DatabaseSetup.call(@db)
    end

    def teardown
      @db.close
    end

    test "find_or_create_message creates a new name" do
      message = @app.send(:find_or_create_message, "Ada")

      assert_equal "Hello, Ada", message
      assert_equal ["Ada"], @app.send(:names)
    end

    test "find_or_create_message recognizes an existing name" do
      @app.send(:find_or_create_message, "Ada")

      message = @app.send(:find_or_create_message, "Ada")

      assert_equal "Hello again, Ada", message
      assert_equal ["Ada"], @app.send(:names)
    end

    test "update_name changes the saved name" do
      @app.send(:find_or_create_message, "Ada")

      message = @app.send(:update_name, "Ada", "Grace")

      assert_equal "Updated Grace", message
      assert_equal ["Grace"], @app.send(:names)
    end

    test "delete_name removes the saved name" do
      @app.send(:find_or_create_message, "Ada")

      @app.send(:delete_name, "Ada")

      assert_empty @app.send(:names)
    end

    test "render_page escapes names and messages" do
      @app.send(:find_or_create_message, "<Ada>")

      html = @app.send(:render_page, "Hello <Ada>")

      assert_includes html, "&lt;Ada&gt;"
      refute_includes html, "<span class=\"name-text\"><Ada></span>"
      assert_includes html, "Hello &lt;Ada&gt;"
      assert_includes html, '<link rel="stylesheet" href="/styles.css">'
      assert_includes html, '<div class="name-row-body">'
      assert_includes html, 'message.classList.add("message-hidden")'
      assert_includes html, 'document.querySelectorAll(\'input[name="delete_name"]\')'
      assert_includes html, 'const rowBody = row?.querySelector(".name-row-body")'
      assert_includes html, 'rowBody?.classList.add("row-shaking")'
      assert_includes html, 'rowBody?.classList.add("row-fading")'
      assert_includes html, "550"
      assert_includes html, "2000"
    end

    test "render_stylesheet returns the shared CSS" do
      css = @app.send(:render_stylesheet)

      assert_includes css, ".message-hidden"
      assert_includes css, ".name-row-body"
      assert_includes css, ".row-shaking"
      assert_includes css, ".row-fading"
      assert_includes css, "@keyframes row-shake"
      assert_includes css, "transition: opacity 0.6s ease;"
    end

    test "blank name is ignored" do
      message = @app.send(:find_or_create_message, "   ")

      assert_nil message
      assert_empty @app.send(:names)
    end
  end
end

WelcomeServer::AppTest.run!
