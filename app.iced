require('dotenv').config()

_ = require('wegweg')({
  globals: on
  shelljs: on
})

require './core/globals'
require './core/listeners'
require './core/startup'

_load_crons = (dir) ->
  return if !_.exists(dir)
  for x in ls "#{dir}/*.iced"
    require("./#{x}")

    if !process.env.SILENCE
      log.info "APP", "Loaded cron: (#{_.base x})"

_load_crons './cron'

app = _.app({
  static: off
  body_parser: on
})

app.use ((req,res,next) ->
  needles = [
    ':ffff:'
    '127.0.0.1'
    '::'
  ]

  for x in needles
    if req.real_ip.includes(x)
      req.real_ip = '127.0.0.1'
      req.real_ip = ip if ip = env.DEVELOPER_DEBUG_IP
      break

  return next()
)

# allow method override
if env.ALLOW_HTTP_METHOD_OVERRIDE
  if !env.SILENCE
    log.warn "APP", 'Allowing HTTP method override using `req.query` (`?method=post`)'

  app.use ((req,res,next) ->
    valid_methods = ['post','delete']

    if req.method is 'GET' and req.query.method
      method = req.query.method.toLowerCase().trim()
      return next() if method !in valid_methods

      req.method = method.toUpperCase().trim()

      if method is 'post'
        body = _.clone req.query
        try delete body.method

        req.query = {}
        req.body = body

    return next()
  )

app.use (require './core/api_response').middleware

if env.DEVELOPER_ERROR_STACK
  if !env.SILENCE
    log.warn 'APP', 'DEVELOPER', "Error stack is exposed via configuration"

app.use (require './core/metadata').middleware

coffee_query = require './core/coffee_query'

app.use coffee_query.parse_extra_filters
app.use coffee_query.middleware

app.use (require './core/request_logging').middleware

app.use (req,res,next) ->
  res.locals.conf = conf
  return next()

if _.exists(dir = __dirname + '/views')
  exphbs  = require('express-handlebars')

  app.engine('.hbs',exphbs({
    layout: no
    extname: '.hbs'
    partialsDir: dir
    helpers: require('./core/hbs_helpers')
  }))

  app.set('view engine','hbs')

  if !env.SILENCE
    log.info "APP", "Adding Handlebars render engine: views/*.hbs"

if _.exists(dir = __dirname + '/static')
  app.use('/static',require('express').static('static'))

  if !env.SILENCE
    log.info "APP", "Serving static assets: static/*: /static"

_mount_routes = (dir,prefix=null) ->
  prefix = "/#{prefix}" if prefix and !prefix.startsWith('/')

  for x in ls "#{dir}/*.iced"
    route = '/' + _.base(x).split('.iced').shift()
    route = prefix + route if prefix
    route = route.split('//').join '/'

    route = '/' if _.base(x).startsWith('_')

    item = require("./#{x}")

    continue if !item.AUTO_EXPOSE

    if item.AUTO_EXPOSE?.route
      route = item.AUTO_EXPOSE.route

    app.use (route), item

    if !process.env.SILENCE
      log.info "AUTO_EXPOSE", "Mounted route: #{route} (#{x})"

_mount_routes './routes'

_auto_expose_models = (->
  return if !conf.mongo

  bind_entity = require './core/auto_expose'

  for model_name in mongoose.modelNames()
    model = mongoose.model(model_name)

    if opts = model.AUTO_EXPOSE

      if !env.SILENCE
        log.info "AUTO_EXPOSE", "Exposing model: #{model_name}", opts

      bind_entity app, (bind_opts = {
        model: model
        route: (opts.route ? '/' + opt.route.toLowerCase())
        methods: (opts.methods ? [])
        statics: (opts.statics ? [])
      })
)

if conf.allow_model_exposure
  _auto_expose_models()
else
  if !process.env.SILENCE
    log.warn "AUTO_EXPOSE", "Model exposure disabled via configuration"

# underscore routes
if conf.allow_underscore_routes
  app.get '/_/ping', (req,res,next) ->
    res.respond {pong:_.uuid()}

  app.get '/_/stats', (req,res,next) ->
    res.respond (require './core/request_logging').stats()

  if !process.env.SILENCE
    log.warn 'APP', 'Underscore routes enabled'

app.use (e,req,res,next) ->
  e = new Error(e) if _.type(e) isnt 'error'
  log.error e
  return res.respond e, 500

app.use (req,res,next) ->
  log.error "404", req.method, req.url
  return res.respond (new Error 'Not found'), 404

if !process.env.SILENCE
  log.info "APP", ":#{conf.port}"

##
app.listen conf.port

