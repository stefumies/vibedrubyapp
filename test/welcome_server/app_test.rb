require "test_helper"

module WelcomeServer
  class AppTest < TestHelper::TestCase
    def setup
      @db = SQLite3::Database.new(":memory:")
      @app = App.new(db: @db)
      @app.send(:setup_db)
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

    test "html escapes names and messages" do
      @app.send(:find_or_create_message, "<Ada>")

      html = @app.send(:html, "Hello <Ada>")

      assert_includes html, "&lt;Ada&gt;"
      refute_includes html, "<span class=\"name-text\"><Ada></span>"
      assert_includes html, "Hello &lt;Ada&gt;"
    end

    test "blank name is ignored" do
      message = @app.send(:find_or_create_message, "   ")

      assert_nil message
      assert_empty @app.send(:names)
    end
  end
end

WelcomeServer::AppTest.run!
