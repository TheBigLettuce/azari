# frozen_string_literal: true

def raise_on_error(out)
  raise out.first.to_s if out.last.exitstatus != 0
end
