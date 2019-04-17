require "uuid"

abstract class Application < ActionController::Base
  before_action :set_request_id
  before_action :set_date_header

  def set_request_id
    response.headers["X-Request-ID"] = request.id = UUID.random.to_s
  end

  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.now)
  end
end
