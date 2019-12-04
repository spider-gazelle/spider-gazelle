# Application dependencies
require "action-controller"
require "active-model"

running_in_production = ENV["SG_ENV"]? == "production"

# Logging configuration
ActionController::Logger.add_tag request_id
ActionController::Logger.add_tag client_ip
# ActionController::Logger.add_tag user_id

# Filter out sensitive params that shouldn't be logged
filter_params = ["password", "bearer_token"]
keeps_headers = ["X-Request-ID"]

# Default log levels
logger = ActionController::Base.settings.logger
logger.level = running_in_production ? Logger::INFO : Logger::DEBUG

# Application code
require "./controllers/application"
require "./controllers/*"
require "./models/*"

# Server required after application controllers
require "action-controller/server"

# Add handlers that should run before your application
ActionController::Server.before(
  ActionController::ErrorHandler.new(!running_in_production, keeps_headers),
  ActionController::LogHandler.new(filter_params),
  HTTP::CompressHandler.new
)

# Optional support for serving of static assests
static_file_path = ENV["PUBLIC_WWW_PATH"]? || "./www"
if File.directory?(static_file_path)
  # Optionally add additional mime types
  ::MIME.register(".yaml", "text/yaml")

  # Check for files if no paths matched in your application
  ActionController::Server.before(
    ::HTTP::StaticFileHandler.new(static_file_path, directory_listing: false)
  )
end

# Configure session cookies
# NOTE:: Change these from defaults
ActionController::Session.configure do |settings|
  settings.key = ENV["COOKIE_SESSION_KEY"]? || "_spider_gazelle_"
  settings.secret = ENV["COOKIE_SESSION_SECRET"]? || "4f74c0b358d5bab4000dd3c75465dc2c"
  # HTTPS only:
  settings.secure = running_in_production
end

APP_NAME = "Spider-Gazelle"
VERSION  = "1.0.0"
