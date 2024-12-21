# frozen_string_literal: true

# Dart CLI commands
class Dart
  PUBSPEC_FILE = "pubspec.yaml"
  DART_EXEC = "dart"

  private_constant :DART_EXEC

  def self.check_conf(dir)
    children = Pathname.new(dir).children(false)

    raise "#{dir} has no pubspec.yaml" unless children.any? { |e| e.to_s == PUBSPEC_FILE }
  end

  def self.run(*command, env: nil)
    res = env.nil? ? Open3.capture2(DART_EXEC, "run", *command) : Open3.capture2(env, DART_EXEC, "run", *command)
    raise_on_error res
  end

  def self.format_file(file)
    raise_on_error Open3.capture2(DART_EXEC, "format", file)
  end
end
