# frozen_string_literal: true

# Regenerate .g.dart files and the Isar FFI bindings
module Regen
  def regen_all(dir, isar_dir)
    Rustup.check
    Cargo.install("cbindgen") if Open3.capture2("which", "cbindgen").last.exitstatus != 0

    Cargo.check_conf(isar_dir)
    Dart.check_conf(dir)

    Flutter.generate(dir, l10n: true)

    Dir.chdir(isar_dir) do
      raise_on_error Open3.capture2(*CBINDGEN_ARGS)
    end

    isar_dir_gen_regen(isar_dir)
  end

  private

  CBINDGEN_ARGS = ["cbindgen", "--config", "cbindgen.toml", "--crate", "isar", "--output",
                   "packages/isar/isar-dart.h"].freeze

  private_constant :CBINDGEN_ARGS

  def isar_dir_gen_regen(isar_dir)
    p_isar_dir = Pathname.new(isar_dir)

    regen_isar_package_isar(p_isar_dir)

    Flutter.generate(p_isar_dir.join("packages/isar_test"))
    Flutter.generate(p_isar_dir.join("packages/isar_inspector"))
  end

  def regen_isar_package_isar(p_isar_dir)
    Dir.chdir(p_isar_dir.join("packages/isar").to_s) do
      Dart.check_conf(Dir.pwd)
      Flutter.pub_get

      command = %(clang -v 2>&1 | grep "Selected GCC installation" | rev | cut -d' ' -f1 | rev)

      clang_dir = Open3.capture2(command).first.strip

      Dart.run("ffigen", "--config", "ffigen.yaml", env: { "CPATH" => "#{clang_dir}/include" })

      Dart.format_file("lib/src/native/bindings.dart")
    end
  end
end
