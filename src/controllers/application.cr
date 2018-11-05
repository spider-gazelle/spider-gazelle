abstract class Application < ActionController::Base
  before_action :set_date_header

  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.now)
  end
end
