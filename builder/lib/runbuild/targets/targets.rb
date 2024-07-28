# frozen_string_literal: true

# Build logic and paths
module Targets
  def self.target_built(dir, target)
    exist = Pathname.new(dir).exist?
    puts "Target is already built: #{target}" if exist

    exist
  end
end
