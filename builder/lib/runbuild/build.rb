# frozen_string_literal: true

# Builds GNU/Linux and Android Isar binaries and moves them to
# expected paths
module Build
  include Targets
  include Targets::Paths

  def run_all(dir)
    check_if_linux

    Cargo.check_conf(dir)
    Rustup.check
    Rustup.check_targets([
      TARGET_LINUX_X64,
      TARGET_LINUX_AARCH64
    ] + android_targets)

    check_lib_dirs_exists(dir)

    Linux.new.run(dir)
    Android.new.run(dir)
  end

  private

  def check_if_linux
    raise "runbuild works only on GNU/linux" unless Open3.capture2("uname").first.strip.eql? "Linux"
  end
end
