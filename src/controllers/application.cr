abstract class Application < ActionController::Base
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
  def time_now
    Time.utc_now.to_s("%a, %d %b %Y %H:%M:%S GMT")
  end
end
