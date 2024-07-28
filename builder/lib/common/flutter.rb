# frozen_string_literal: true

# Flutter CLI commands
class Flutter
  FLUTTER_EXEC = "flutter"
  BUILDRUNNER_ARGS = ["pub", "run", "build_runner", "build",
                      "--delete-conflicting-outputs"].freeze

  private_constant :FLUTTER_EXEC, :BUILDRUNNER_ARGS

  def self.pub_get
    raise_on_error Open3.capture2(FLUTTER_EXEC, "pub", "get")
  end

  def self.generate(dir, l10n: false)
    Dir.chdir(dir) do
      pub_get
      raise_on_error Open3.capture2(FLUTTER_EXEC, "gen-l10n") if l10n

      raise_on_error Open3.capture2(FLUTTER_EXEC, *BUILDRUNNER_ARGS)
    end
  end
end
