# Application dependencies
require "action-controller"
require "active-model"
require "./constants"

# Logging configuration
ActionController::Logger.add_tag request_id
ActionController::Logger.add_tag client_ip
# ActionController::Logger.add_tag user_id

# Filter out sensitive params that shouldn't be logged
filter_params = ["password", "bearer_token"]
keeps_headers = ["X-Request-ID"]

# Default log levels
logger = ActionController::Base.settings.logger
logger.level = App.running_in_production? ? Logger::INFO : Logger::DEBUG

# Application code
require "./controllers/application"
require "./controllers/*"
require "./models/*"

# Server required after application controllers
require "action-controller/server"

# Add handlers that should run before your application
ActionController::Server.before(
  ActionController::ErrorHandler.new(!App.running_in_production?, keeps_headers),
  ActionController::LogHandler.new(filter_params),
  HTTP::CompressHandler.new
)

# Optional support for serving of static assests
if File.directory?(App::STATIC_FILE_PATH)
  # Optionally add additional mime types
  ::MIME.register(".yaml", "text/yaml")

  # Check for files if no paths matched in your application
  ActionController::Server.before(
    ::HTTP::StaticFileHandler.new(App::STATIC_FILE_PATH, directory_listing: false)
  )
end

# Configure session cookies
# NOTE:: Change these from defaults
ActionController::Session.configure do |settings|
  settings.key = App::COOKIE_SESSION_KEY
  settings.secret = App::COOKIE_SESSION_SECRET
  # HTTPS only:
  settings.secure = App.running_in_production?
end
