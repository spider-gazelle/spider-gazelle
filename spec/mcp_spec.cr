require "./spec_helper"

describe "MCP server" do
  router = AC::SpecHelper.new
  ActionController::MCPServer.mount(router, App::MCP_PATH)
  client = router.hot_topic

  headers = HTTP::Headers{
    "Content-Type" => "application/json",
    "Accept"       => "application/json",
  }

  # sends a JSON-RPC request, returning the result
  rpc = ->(method : String, params : Hash(String, JSON::Any)) do
    body = {jsonrpc: "2.0", id: 1, method: method, params: params}.to_json
    response = client.post(App::MCP_PATH, headers: headers, body: body)
    response.status_code.should eq 200
    JSON.parse(response.body)["result"]
  end

  # the server is stateless: there's no session, so each request stands alone
  it "initializes" do
    result = rpc.call("initialize", {"protocolVersion" => JSON::Any.new("2025-11-25")})
    result["serverInfo"]["name"].should eq App::NAME
    result["capabilities"]["prompts"]["listChanged"].should be_false
  end

  it "exposes the routes as tools" do
    # tools with a card are root items, always listed
    tools = rpc.call("tools/list", {} of String => JSON::Any)["tools"].as_a.map(&.["name"].as_s)
    tools.should contain "welcome_api"

    # other tools are in the controller's toolbox, opening it returns their definitions
    opened = rpc.call("tools/call", {"name" => JSON::Any.new("open_toolbox"), "arguments" => JSON.parse(%({"name": "welcome"}))})
    toolbox = opened["structuredContent"]["tools"].as_a.map(&.["name"].as_s)
    toolbox.should contain "welcome_index"

    # hidden with `@[AC::MCP(hide: true)]`
    (tools + toolbox).should_not contain "welcome_openapi"

    result = rpc.call("tools/call", {"name" => JSON::Any.new("welcome_api"), "arguments" => JSON.parse(%({"example": 42}))})
    result["structuredContent"].should eq({"status" => 200, "body" => {"result" => 42}})
  end

  it "serves the example prompt" do
    prompts = rpc.call("prompts/list", {} of String => JSON::Any)["prompts"].as_a
    prompt = prompts.find! { |entry| entry["name"] == "welcome_number_fact" }
    prompt["arguments"].as_a.map { |arg| {arg["name"].as_s, arg["required"].as_bool} }.should eq [{"number", true}, {"audience", false}]

    result = rpc.call("prompts/get", {"name" => JSON::Any.new("welcome_number_fact"), "arguments" => JSON.parse(%({"number": "7", "audience": "a pirate"}))})
    text = result["messages"][0]["content"]["text"].as_s
    text.should start_with "Share one surprising fact about the number 7, explained for a pirate."
  end
end
