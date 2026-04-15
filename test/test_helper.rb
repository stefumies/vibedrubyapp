$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "sqlite3"
require "welcome_server/app"

module TestHelper
  class AssertionFailed < StandardError; end

  module Assertions
    def assert(condition, message = "assertion failed")
      raise AssertionFailed, message unless condition
    end

    def assert_equal(expected, actual, message = nil)
      return if expected == actual

      raise AssertionFailed, message || "Expected #{expected.inspect}, got #{actual.inspect}"
    end

    def assert_nil(value, message = nil)
      return if value.nil?

      raise AssertionFailed, message || "Expected nil, got #{value.inspect}"
    end

    def assert_empty(value, message = nil)
      return if value.respond_to?(:empty?) && value.empty?

      raise AssertionFailed, message || "Expected empty value, got #{value.inspect}"
    end

    def assert_includes(haystack, needle, message = nil)
      return if haystack.include?(needle)

      raise AssertionFailed, message || "Expected #{haystack.inspect} to include #{needle.inspect}"
    end

    def refute_includes(haystack, needle, message = nil)
      return unless haystack.include?(needle)

      raise AssertionFailed, message || "Expected #{haystack.inspect} not to include #{needle.inspect}"
    end
  end

  class TestCase
    include Assertions

    def self.test(name, &block)
      tests << [name, block]
    end

    def self.run!
      failures = []

      tests.each do |name, block|
        instance = new

        begin
          instance.setup if instance.respond_to?(:setup)
          instance.instance_eval(&block)
          puts "PASS #{name}"
        rescue StandardError => e
          failures << [name, e]
          warn "FAIL #{name}: #{e.message}"
        ensure
          instance.teardown if instance.respond_to?(:teardown)
        end
      end

      return if failures.empty?

      warn
      failures.each do |name, error|
        warn "#{name}: #{error.class}: #{error.message}"
      end
      exit 1
    end

    def self.tests
      @tests ||= []
    end
  end
end
