# frozen_string_literal: true

module Targets
  # GNU/Linux target of Isar libraries
  class Linux
    include Paths

    def run(dir)
      arch = system_arch
      target = choose_target arch
      return if Targets.target_built(path_lib_linux(dir), target)

      command = Cargo.fmt_build_command target

      run_build(dir, target, command)
    end

    private

    def system_arch
      Open3.capture2("uname", "-m").first.strip
    end

    def choose_target(arch)
      if arch.eql? "x86_64"
        TARGET_LINUX_X64
      else
        TARGET_LINUX_AARCH64
      end
    end

    def run_build(dir, target, command)
      Dir.chdir(dir) do
        Open3.popen2(command) do |stdin, stdout, wait_thread|
        end

        lib = Pathname.new(Cargo.target_out_lib_rel(target))
        raise "run cargo build but no file" unless lib.file?

        lib.rename(path_lib_linux(dir))
      end
    end
  end
end
