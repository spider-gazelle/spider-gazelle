require "uuid"
require "yaml"

abstract class Application < ActionController::Base
  # Configure your log source name
  # NOTE:: this is chaining from App::Log
  Log = ::App::Log.for("controller")

  # framework uses "application/json" by default
  add_responder("application/yaml") { |io, result| result.to_yaml(io) }
  add_responder("text/html") { |io, result| result.to_json(io) }

  # This makes it simple to match client requests with server side logs.
  # When building microservices this ID should be propagated to upstream services.
  @[AC::Route::Filter(:before_action)]
  def set_request_id
    request_id = UUID.random.to_s
    Log.context.set(
      client_ip: client_ip,
      request_id: request_id
    )
    response.headers["X-Request-ID"] = request_id

    # If this is an upstream service, the ID should be extracted from a request header.
    # request_id = request.headers["X-Request-ID"]? || UUID.random.to_s
    # Log.context.set client_ip: client_ip, request_id: request_id
    # response.headers["X-Request-ID"] = request_id
  end

  @[AC::Route::Filter(:before_action)]
  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.utc)
  end

  # Provides details on available data formats
  struct ContentError
    include JSON::Serializable
    include YAML::Serializable

    getter error : String
    getter accepts : Array(String)? = nil

    def initialize(@error, @accepts = nil)
    end
  end

  # covers no acceptable response format and not an acceptable post format
  @[AC::Route::Exception(AC::Route::NotAcceptable, status_code: HTTP::Status::NOT_ACCEPTABLE)]
  @[AC::Route::Exception(AC::Route::UnsupportedMediaType, status_code: HTTP::Status::UNSUPPORTED_MEDIA_TYPE)]
  def bad_media_type(error) : ContentError
    ContentError.new error: error.message.as(String), accepts: error.accepts
  end

  # Provides details on which parameter is missing or invalid
  struct ParameterError
    include JSON::Serializable
    include YAML::Serializable

    getter error : String
    getter parameter : String? = nil
    getter restriction : String? = nil

    def initialize(@error, @parameter = nil, @restriction = nil)
    end
  end

  # handles paramater missing or a bad paramater value / format
  @[AC::Route::Exception(AC::Route::Param::MissingError, status_code: HTTP::Status::UNPROCESSABLE_ENTITY)]
  @[AC::Route::Exception(AC::Route::Param::ValueError, status_code: HTTP::Status::BAD_REQUEST)]
  def invalid_param(error) : ParameterError
    ParameterError.new error: error.message.as(String), parameter: error.parameter, restriction: error.restriction
  end
end
