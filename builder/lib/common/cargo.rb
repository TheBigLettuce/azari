# frozen_string_literal: true

# Cargo CLI commands
class Cargo
  CARGO_FILE = "Cargo.toml"

  def self.fmt_build_command(target_arch)
    "cargo build --target #{target_arch} --release"
  end

  def self.target_out_lib_rel(target)
    "target/#{target}/release/libisar.so"
  end

  def self.install(crate)
    raise "Couldn't install crate: #{crate}" if Open3.capture2("cargo", "install", crate).last.exitstatus != 0
  end

  def self.check_conf(dir)
    children = Pathname.new(dir).children(false)

    raise "#{dir} has no Cargo.toml" unless children.any? { |e| e.to_s == CARGO_FILE }
  end
end
