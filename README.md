# Spider-Gazelle Application Template

Clone this repository to start building your own spider-gazelle based application

## Testing

`crystal spec`

* to run in development mode `crystal ./src/app.cr`

## Compiling

`crystal build ./src/app.cr`

### Deploying

Once compiled you are left with a binary `./app`

* for help `./app --help`
* viewing routes `./app --routes`
* run on a different port or host `./app -h 0.0.0.0 -p 80`
