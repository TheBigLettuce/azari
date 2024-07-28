# frozen_string_literal: true

# Rustup commandline tool
class Rustup
  def self.check
    raise "rustup not found" if Open3.capture2("which", "rustup").last.exitstatus != 0
    raise "rustc not found" if Open3.capture2("which", "rustc").last.exitstatus != 0
    raise "cargo not found" if Open3.capture2("which", "cargo").last.exitstatus != 0
  end

  def self.check_targets(required_targets)
    installed_targets = Open3.capture2("rustup", "target", "list", "--installed").first.split($ORS).to_h do |target|
      [target, nil]
    end

    add_targets_if_needed(required_targets, installed_targets)
  end

  def self.add_targets_if_needed(required_targets, installed_targets)
    required_targets.each do |e|
      add_target(e) unless installed_targets.key?(e)
    end
  end

  def self.add_target(target)
    raise "Adding #{target} failed" if Open3.capture2("rustup", "target", "add", target).last.exitstatus != 0
  end

  private_class_method :add_target, :add_targets_if_needed
end
