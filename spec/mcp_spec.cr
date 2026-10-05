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

  initialize_result = JSON::Any.new(nil)

  # every request after `initialize` belongs to the session
  before_all do
    response = client.post(App::MCP_PATH, headers: headers, body: {
      jsonrpc: "2.0", id: 1, method: "initialize", params: {protocolVersion: "2025-11-25"},
    }.to_json)
    response.status_code.should eq 200
    headers["Mcp-Session-Id"] = response.headers["Mcp-Session-Id"]
    initialize_result = JSON.parse(response.body)["result"]
  end

  it "establishes a session" do
    initialize_result["serverInfo"]["name"].should eq App::NAME
    initialize_result["capabilities"]["prompts"]["listChanged"].should be_true
  end

  it "exposes the routes as tools" do
    rpc.call("tools/call", {"name" => JSON::Any.new("open_toolbox"), "arguments" => JSON.parse(%({"name": "welcome"}))})
    tools = rpc.call("tools/list", {} of String => JSON::Any)["tools"].as_a.map(&.["name"].as_s)
    tools.should contain "welcome_api"

    # hidden with `@[AC::MCP(hide: true)]`
    tools.should_not contain "welcome_openapi"

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
