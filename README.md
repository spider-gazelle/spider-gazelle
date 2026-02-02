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
