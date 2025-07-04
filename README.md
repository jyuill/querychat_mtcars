# querychat_mtcars
Example of using gen AI to query data in a shiny dashboard using the Posit querychat package.

* based on example from https://github.com/posit-dev/querychat/blob/main/pkg-r/README.md
* extensive system prompting handled behind the scenes
    * see https://github.com/posit-dev/querychat/blob/main/pkg-r/inst/prompt/prompt.md for details
* some customization: greeting, data description (recommended), model selection (using ellmer pkg), charts in interface
* data source: mtcars with minor modifications
* duckdb under the hood to write SQL queries against - all handled via the querychat package
* API key needed for Claude model
* published to Posit Connect Cloud
    * need to create manifest.json file to set requirements
    * run: rsconnect::writeManifest(appPrimaryDoc = "app.R") (can be run from manifest-update.R)
