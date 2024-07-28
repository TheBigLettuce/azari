# frozen_string_literal: true

module Targets
  # In and out paths for target files and
  # target constants themselves
  module Paths
    TARGET_LINUX_X64 = "x86_64-unknown-linux-gnu"
    TARGET_LINUX_AARCH64 = "aarch64-unknown-linux-gnu"

    TARGET_ANDROID_X86 = "i686-linux-android"
    TARGET_ANDROID_X64 = "x86_64-linux-android"
    TARGET_ANDROID_ARMV7 = "armv7-linux-androideabi"
    TARGET_ANDROID_AARCH64 = "aarch64-linux-android"

    def android_targets
      [TARGET_ANDROID_X86, TARGET_ANDROID_X64, TARGET_ANDROID_ARMV7, TARGET_ANDROID_AARCH64]
    end

    def path_lib_linux(dir)
      "#{dir}/#{LINUX_LIB_DIR}/libisar.so"
    end

    def path_lib_android(dir, target)
      case target
      when TARGET_ANDROID_ARMV7
        "#{dir}/#{ANDROID_LIB_DIR}/armeabi-v7a/libisar.so"
      when TARGET_ANDROID_AARCH64
        "#{dir}/#{ANDROID_LIB_DIR}/arm64-v8a/libisar.so"
      when TARGET_ANDROID_X64
        "#{dir}/#{ANDROID_LIB_DIR}/x86_64/libisar.so"
      when TARGET_ANDROID_X86
        "#{dir}/#{ANDROID_LIB_DIR}/x86/libisar.so"
      else
        raise "#{target} is not an Android target"
      end
    end

    def check_lib_dirs_exists(dir)
      dir_p = Pathname.new(dir)

      check_path_exist dir_p.join(ANDROID_LIB_DIR)
      check_path_exist dir_p.join(LINUX_LIB_DIR)
    end

    ANDROID_LIB_DIR = "packages/isar_flutter_libs/android/src/main/jniLibs"
    LINUX_LIB_DIR = "packages/isar_flutter_libs/linux"

    private_constant :ANDROID_LIB_DIR, :LINUX_LIB_DIR

    private

    def check_path_exist(dir)
      raise "#{dir} doesn't exist" unless Pathname.new(dir).exist?
    end
  end
end
