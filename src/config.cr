# Application dependencies
require "action-controller"
require "./constants"

# Application code
require "./controllers/application"
require "./controllers/*"
require "./models/*"

# Server required after application controllers
require "action-controller/server"

module App
  # Configure logging (backend defined in constants.cr)
  if running_in_production?
    log_level = ::Log::Severity::Info
    ::Log.setup "*", :warn, LOG_BACKEND
  else
    log_level = ::Log::Severity::Debug
    ::Log.setup "*", :info, LOG_BACKEND
  end
  ::Log.builder.bind "action-controller.*", log_level, LOG_BACKEND
  ::Log.builder.bind "#{NAME}.*", log_level, LOG_BACKEND

  # Filter out sensitive params that shouldn't be logged
  filter_params = ["password", "bearer_token"]
  keeps_headers = ["X-Request-ID"]

  # Add handlers that should run before your application
  ActionController::Server.before(
    ActionController::ErrorHandler.new(running_in_production?, keeps_headers),
    ActionController::LogHandler.new(filter_params),
    HTTP::CompressHandler.new
  )

  # Optional support for serving of static assests
  if File.directory?(STATIC_FILE_PATH)
    # Optionally add additional mime types
    ::MIME.register(".yaml", "text/yaml")

    # Check for files if no paths matched in your application
    ActionController::Server.before(
      ::HTTP::StaticFileHandler.new(STATIC_FILE_PATH, directory_listing: false)
    )
  end

  # Configure session cookies
  # NOTE:: Change these from defaults
  ActionController::Session.configure do |settings|
    settings.key = COOKIE_SESSION_KEY
    settings.secret = COOKIE_SESSION_SECRET
    # HTTPS only:
    settings.secure = running_in_production?
  end
end
