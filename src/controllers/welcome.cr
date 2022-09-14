# description of the welcome klass
class Welcome < Application
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
  # the various responses are returned based on the Accepts header
  @[AC::Route::GET("/api/:example")]
  @[AC::Route::POST("/api/:example")]
  @[AC::Route::GET("/api/other/route")]
  def api(example : Int32) : NamedTuple(result: Int32)
    {
      result: example,
    }
  end

  # this file is built as part of the docker build
  OPENAPI = YAML.parse(File.exists?("openapi.yml") ? File.read("openapi.yml") : "{}")

  # returns the OpenAPI representation of this service
  @[AC::Route::GET("/openapi")]
  def openapi : YAML::Any
    OPENAPI
  end
end
