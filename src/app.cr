require "option_parser"
require "./constants"

# Server defaults
port = App::DEFAULT_PORT
host = App::DEFAULT_HOST
process_count = App::DEFAULT_PROCESS_COUNT
exit_code = nil

# Command line options
OptionParser.parse(ARGV.dup) do |parser|
  parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"

  parser.on("-b HOST", "--bind=HOST", "Specifies the server host") { |h| host = h }
  parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |p| port = p.to_i }

  parser.on("-w COUNT", "--workers=COUNT", "Specifies the number of processes to handle requests") do |w|
    process_count = w.to_i
  end

  parser.on("-r", "--routes", "List the application routes") do
    ActionController::Server.print_routes
    exit 0
  end

  parser.on("-v", "--version", "Display the application version") do
    puts "#{App::NAME} v#{App::VERSION}"
    exit 0
  end

  parser.on("-c URL", "--curl=URL", "Perform a basic health check by requesting the URL") do |url|
    begin
      response = HTTP::Client.get url
      exit 0 if (200..499).includes? response.status_code
      puts "health check failed, received response code #{response.status_code}"
      exit 1
    rescue error
      error.inspect_with_backtrace(STDOUT)
      exit 2
    end
  end

  parser.on("-d", "--docs", "Outputs OpenAPI documentation for this service") do
    docs = ActionController::OpenAPI.generate_open_api_docs(
      title: App::NAME,
      version: App::VERSION,
      description: "App description for OpenAPI docs"
    ).to_yaml

    parser.on("-f FILE", "--file=FILE", "Save the docs to a file") do |file|
      File.write(file, docs)
    end

    puts docs
    exit_code = 0
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit 0
  end
end

if exit_code
  exit exit_code.as(Int32)
end

# Load the routes
puts "Launching #{App::NAME} v#{App::VERSION}"

# Requiring config here ensures that the option parser runs before
# attempting to connect to databases etc.
require "./config"
server = ActionController::Server.new(port, host)

# (process_count < 1) == `System.cpu_count` but this is not always accurate
# Clustering using processes, there is no forking once crystal threads drop
server.cluster(process_count, "-w", "--workers") if process_count != 1

terminate = Proc(Signal, Nil).new do |signal|
  puts " > terminating gracefully"
  spawn { server.close }
  signal.ignore
end

# Detect ctr-c to shutdown gracefully
# Docker containers use the term signal
Signal::INT.trap &terminate
Signal::TERM.trap &terminate

# Allow signals to change the log level at run-time
# Turn on DEBUG level logging `kill -s USR1 %PID`
App.register_severity_switch_signals

# Start the server
server.run do
  puts "Listening on #{server.print_addresses}"
end

# Shutdown message
puts "#{App::NAME} leaps through the veldt\n"
