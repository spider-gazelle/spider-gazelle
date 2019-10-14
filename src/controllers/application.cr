require "uuid"

abstract class Application < ActionController::Base
  before_action :set_request_id
  before_action :set_date_header

  # This makes it simple to match client requests with server side logs.
  # When building microservices this ID should be propagated to upstream services.
  def set_request_id
    response.headers["X-Request-ID"] = logger.request_id = UUID.random.to_s

    # If this is an upstream service, the ID should be extracted from a request header.
    # response.headers["X-Request-ID"] = logger.request_id = request.headers["X-Request-ID"]? || UUID.random.to_s
  end

  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.utc)
  end
end
