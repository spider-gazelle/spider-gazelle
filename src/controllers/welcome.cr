# Use welcome to obtain a welcome message and turn a number into a result.
class App::Welcome < App::Base
  base "/"

  # A welcome message
  @[AC::Route::GET("/")]
  def index : String
    welcome_text = "You're being trampled by Spider-Gazelle!"
    Log.warn { "logs can be collated using the request ID" }

    # You can use signals to change log levels at runtime
    # USR1 is debugging, USR2 is info
    # `kill -s USR1 %APP_PID`
    Log.debug { "use signals to change log levels at runtime" }

    welcome_text
  end

  # For API applications the return value of the function is expected to work with
  # all of the responder blocks (see application.cr)
  # the various responses are returned based on the Accepts header.
  # Doc comments directly above a route describe it in the OpenAPI docs and MCP tools.

  # Returns the example number provided as the result
  @[AC::Route::GET("/api/:example")]
  @[AC::Route::POST("/api/:example")]
  @[AC::Route::GET("/api/other/route")]
  def api(
    @[AC::Param::Info(description: "provide an example number to have it returned as the result", example: "3")]
    example : Int32,
  ) : NamedTuple(result: Int32)
    {
      result: example,
    }
  end

  # An example MCP prompt, a reusable message template users can select in their
  # MCP client. Prompts are not HTTP routes, but arguments are parsed and filters
  # applied exactly as they are for routes. `root: true` lists it without the user
  # opening the welcome toolbox. Return a String, or `Array(AC::PromptMessage)` for
  # a conversation. The doc comment below is the description users see.

  # Learn a surprising fact about a number
  @[AC::MCP(prompt: true, root: true)]
  def number_fact(
    @[AC::Param::Info(description: "the number to share a fact about", example: "42")]
    number : Int32,
    @[AC::Param::Info(description: "who the fact is for", example: "a curious five year old")]
    audience : String = "a general audience",
  ) : String
    <<-PROMPT
      Share one surprising fact about the number #{number}, explained for #{audience}.
      Use the welcome toolbox to confirm the number with this service first.
      PROMPT
  end

  # this file is built as part of the docker build
  OPENAPI = YAML.parse(File.exists?("openapi.yml") ? File.read("openapi.yml") : "{}")

  # `hide: true` excludes a route from the MCP tools, the OpenAPI document isn't
  # useful to an LLM.

  # returns the OpenAPI representation of this service
  @[AC::MCP(hide: true)]
  @[AC::Route::GET("/openapi")]
  def openapi : YAML::Any
    OPENAPI
  end
end
