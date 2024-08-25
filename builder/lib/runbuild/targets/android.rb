# frozen_string_literal: true

module Targets
  # Android target of Isar libraries
  class Android
    include Paths

    def run(dir)
      ndk_dir_bin = find_ndk

      env = prepare_env_vars(ndk_dir_bin)
      android_targets.each do |target|
        next if Targets.target_built(path_lib_android(dir, target), target)

        command = Cargo.fmt_build_command target

        run_build(env, dir, target, command)
      end
    end

    private

    def find_ndk
      android_sdk = ENV["ANDROID_SDK_ROOT"]

      raise "Android SDK not found" if android_sdk.empty?

      android_sdk_path = Pathname.new(android_sdk)

      raise "Android SDK is not a directory" unless android_sdk_path.directory?

      android_ndk_path = android_sdk_path.join("ndk")

      raise "Android NDK not found" unless android_ndk_path.exist?

      select_ndk_version android_ndk_path
    end

    def select_ndk_version(android_ndk_path)
      children = android_ndk_path.children(false).sort { |a, b| b <=> a }

      raise "No NDK versions has been found at #{android_ndk_path}" if children.empty?

      ndk_dir_bin = android_ndk_path.join(children.first.join("toolchains/llvm/prebuilt/linux-x86_64/bin"))

      raise "#{ndk_dir_bin} doesn't exist" unless ndk_dir_bin.exist?

      ndk_dir_bin.to_s
    end

    def prepare_env_vars(ndk_dir_bin) # rubocop:disable Metrics/MethodLength
      prev_path = ENV["PATH"]

      {
        "PATH" => "#{ndk_dir_bin}:#{prev_path}",

        "CARGO_TARGET_I686_LINUX_ANDROID_LINKER" => "#{ndk_dir_bin}/i686-linux-android21-clang",
        "CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER" => "#{ndk_dir_bin}/x86_64-linux-android21-clang",
        "CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER" => "#{ndk_dir_bin}/armv7a-linux-androideabi21-clang",
        "CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER" => "#{ndk_dir_bin}/aarch64-linux-android21-clang",

        "CARGO_TARGET_I686_LINUX_ANDROID_AR" => "#{ndk_dir_bin}/llvm-ar",
        "CARGO_TARGET_X86_64_LINUX_ANDROID_AR" => "#{ndk_dir_bin}/llvm-ar",
        "CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_AR" => "#{ndk_dir_bin}/llvm-ar",
        "CARGO_TARGET_AARCH64_LINUX_ANDROID_AR" => "#{ndk_dir_bin}/llvm-ar",

        "CC_i686_linux_android" => "#{ndk_dir_bin}/i686-linux-android21-clang",
        "CC_x86_64_linux_android" => "#{ndk_dir_bin}/x86_64-linux-android21-clang",
        "CC_armv7_linux_androideabi" => "#{ndk_dir_bin}/armv7a-linux-androideabi21-clang",
        "CC_aarch64_linux_android" => "#{ndk_dir_bin}/aarch64-linux-android21-clang",

        "AR_i686_linux_android" => "#{ndk_dir_bin}/llvm-ar",
        "AR_x86_64_linux_android" => "#{ndk_dir_bin}/llvm-ar",
        "AR_armv7_linux_androideabi" => "#{ndk_dir_bin}/llvm-ar",
        "AR_aarch64_linux_android" => "#{ndk_dir_bin}/llvm-ar"
      }
    end

    def run_build(env, dir, target, command)
      Dir.chdir(dir) do
        Open3.popen2(env, command) do |stdin, stdout, wait_thread|
        end

        lib = Pathname.new(Cargo.target_out_lib_rel(target))
        raise "run cargo build but no file" unless lib.file?

        lib_path_out = path_lib_android(dir, target)
        lib_dir_out = Pathname.new(lib_path_out).dirname

        lib_dir_out.mkdir unless lib_dir_out.exist?

        lib.rename(lib_path_out)
      end
    end
  end
end
