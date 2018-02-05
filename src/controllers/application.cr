# Require kilt for template support
require "kilt"

abstract class Application < ActionController::Base
  before_action :set_date_header

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
  def time_now
    Time.utc_now.to_s("%a, %d %b %Y %H:%M:%S GMT")
  end

  def set_date_header
    response.headers["Date"] = time_now
  end
end
