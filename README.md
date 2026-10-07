# Spider-Gazelle Application Template

[![CI](https://github.com/spider-gazelle/spider-gazelle/actions/workflows/ci.yml/badge.svg)](https://github.com/spider-gazelle/spider-gazelle/actions/workflows/ci.yml)

Clone this repository to start building your own spider-gazelle based application.
This is a template and as such, Do What the Fuck You Want To

## Documentation

Detailed documentation and guides available: https://spider-gazelle.net/

* [Action Controller](https://github.com/spider-gazelle/action-controller) base class for building [Controllers](http://guides.rubyonrails.org/action_controller_overview.html)
* [Active Model](https://github.com/spider-gazelle/active-model) base class for building [ORMs](https://en.wikipedia.org/wiki/Object-relational_mapping)
* [Habitat](https://github.com/luckyframework/habitat) configuration and settings for Crystal projects
* [lucky_router](https://github.com/luckyframework/lucky_router) base request handling and routing
* [HTTP::Server](https://crystal-lang.org/api/latest/HTTP/Server.html) built-in Crystal Lang HTTP server
  * Request
  * Response
  * Cookies
  * Headers
  * Params etc

Spider-Gazelle builds on the amazing performance of [lucky_router](https://github.com/luckyframework/lucky_router). :rocket:

## OpenAPI

Routes defined with annotations are described in an [OpenAPI](https://www.openapis.org/)
document, generated from the code:

* **Routes and parameters** come from the route annotations and method signatures.
* **Descriptions** come from the doc comments directly above controllers and methods.
* **Parameter details** come from `@[AC::Param::Info(description: "...", example: "...")]`.
* **Request and response schemas** come from the argument and return types.

```crystal
# Returns the example number provided as the result
@[AC::Route::GET("/api/:example")]
def api(
  @[AC::Param::Info(description: "provide an example number to have it returned as the result", example: "3")]
  example : Int32,
) : NamedTuple(result: Int32)
  {result: example}
end
```

Comments are extracted with `crystal docs`, so the document is generated where the
source code is available:

```shell
./app --docs                    # print the document
./app --docs --file=openapi.yml # save it
```

The Dockerfile generates `openapi.yml` during the build and copies it into the image.
The template serves it at `GET /openapi`.

## MCP Server

The application is also an [MCP](https://modelcontextprotocol.io) server, so LLM
clients (Claude Code, Claude Desktop, VS Code, Cursor, ...) can use your API. It's
served at `/mcp` over the Streamable HTTP transport.

```shell
claude mcp add --transport http my-app http://localhost:3000/mcp
```

* **Tools:** every annotated route is a tool, described by the same comments and
  annotations as the OpenAPI docs. Controllers are grouped into toolboxes, and a
  session starts with `list_toolboxes`, `open_toolbox` and `close_toolbox`, so the
  model only loads the tools it needs. Clients that don't refresh their tools when
  a toolbox opens (currently Claude and ChatGPT) run them through `call_tool`.
* **UI cards:** `@[AC::MCP(ui: "welcome/result.html")]` renders `cards/welcome/result.html`
  for the tool's results in MCP clients that support [MCP Apps](https://github.com/modelcontextprotocol/ext-apps),
  such as Claude and ChatGPT. See `Welcome#api` and the card for an example.
* **Prompts:** reusable message templates users can pick in their client. Mark a
  method with `@[AC::MCP(prompt: true)]`. It returns a `String`, or an
  `Array(AC::PromptMessage)` for a conversation. Prompts aren't HTTP routes, but
  their arguments are parsed and your filters run exactly as for routes. See
  `Welcome#number_fact` for an example.
* **Visibility:**
  * `@[AC::MCP(hide: true)]` excludes a route or controller (see `Welcome#openapi`).
  * `@[AC::MCP(root: true)]` makes a tool or prompt available without opening its
    toolbox.
* **Descriptions:** like the OpenAPI docs, these need the source code, so the
  Dockerfile generates `mcp.yml` (`./app --mcp=mcp.yml`) and ships it with the
  binary. Without it, the server still works but descriptions are missing.
* **Authentication:** optional, and off by default. Your routes' own authentication
  applies to every tool call (`Authorization`, `Cookie` and `X-API-Key` headers are
  forwarded). To have MCP clients sign users in with OAuth, uncomment
  `auth_probe` and `resource_metadata` in `src/config.cr`.

Configuration lives in `src/config.cr`. The environment variables are:

| Variable | Default | Purpose |
|----------|---------|---------|
| `SG_MCP_PATH` | `/mcp` | Endpoint path, an empty string disables the MCP server |
| `SG_MCP_DESCRIPTION` | `mcp.yml` | Location of the generated tool descriptions |
| `SG_MCP_UI` | `./cards` | Folder of MCP Apps cards, HTML rendered by MCP clients for tool results |

See the [action-controller README](https://github.com/spider-gazelle/action-controller#mcp-server)
for the full reference.

## Testing

`crystal spec`

* to run in development mode `crystal ./src/app.cr`

## Compiling

`crystal build ./src/app.cr`

### Deploying

Once compiled you are left with a binary `./app`

* for help `./app --help`
* viewing routes `./app --routes`
* run on a different port or host `./app -b 0.0.0.0 -p 80`
* generate the OpenAPI docs `./app --docs --file=openapi.yml`
* generate the MCP tool descriptions `./app --mcp=mcp.yml`
