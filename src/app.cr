require "option_parser"
require "./config"

# Default port
port = 3000

# Command line options
OptionParser.parse! do |parser|
  parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"

  parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |p| port = p.to_i }

  parser.on("-r", "--routes", "List the application routes") do
    ActionController::Server.print_routes
    exit 0
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit 0
  end
end

# Start the server
server = ActionController::Server.new(port)
server.run
