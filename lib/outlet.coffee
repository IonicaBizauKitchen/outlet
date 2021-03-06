express  = require "express"
logfmt   = require "logfmt"
https    = require "https"
cors     = require "cors"
mongoose = require "mongoose"
Plugin   = require "../lib/plugin"

mongoose.connect(process.env.MONGOHQ_URL)

app = express()
app.use express.bodyParser()
app.use logfmt.requestLogger()
app.use app.router
app.use '/', express.static('public')

app.get "/reset", (req, res) ->
  Plugin.collection.drop (err) ->
    return res.jsonp(400, {error: err}) if err
    res.jsonp(200, {message: "plugin collection dropped"})

app.get "/plugins", cors(), (req, res) ->
  Plugin.find (err, plugins) ->
    return res.jsonp(400, {error: err}) if err
    res.jsonp plugins

app.post "/plugins", cors(), (req, res) ->

  # Extract user and repo from URL string
  if req.body.repo
    obj = require('github-url-to-object')(req.body.repo)
    req.body.user = obj.user
    req.body.repo = obj.repo

  # Assemble user/repo pair string
  gid = [req.body.user, req.body.repo].join("/")

  Plugin.fetch gid, (err, plugin) =>
    return res.jsonp(400, {error: err}) if err
    res.redirect('/')

app.get "/plugins/:user/:repo", cors(), (req, res) ->
  gid = [req.params.user, req.params.repo].join("/")
  Plugin.fetch gid, (err, plugin) =>
    return res.jsonp(400, {error: err}) if err
    res.jsonp(plugin)

module.exports = app