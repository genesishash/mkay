<p align="xcenter">
  <img src="https://taky.s3.amazonaws.com/51h0j3s95801.png" width="282">
</p>

# mkay framework
iced/express/mongo/mongoose/redis/memcached/winston
_build scalable apis really, really fast, mkay?_

# goals
- to produce very fast development of complex backends by being super opinionated
- to inevitably break some rules, but as few as possible
- eliminate redundancy
- eliminate redundancy (see what i did?)

# quick start

```bash
git clone https://github.com/tosadvisor/mkay
cd ./mkay
sudo npm i -g iced-coffee-script
npm i --unsafe-perm
iced app.iced
```

### generate a model

```bash
cd ./models
./_create --name friends > friends.iced
```

- rest crud is automatically bound if `model.AUTO_EXPOSE` is exported
- expose instance methods using `model.AUTO_EXPOSE.methods`
- expose static methods using `model.AUTO_EXPOSE.statics`

### create a new "friend"

`http://localhost:10001/friends?method=post&name=John`

<img src="https://taky.s3.amazonaws.com/91gx71e555s1.png" width="250">

- list `/friends`
- view `/friends/:_id`
- edit `/friends/:_id/?method=post&name=James`
- delete `/friends/:_id/?method=delete`

### create and expose an instance method

add a method to `FriendsSchema`. automatically exposed methods must always
take an object as the first parameter, the second must be a callback

```coffeescript
FriendsSchema.methods.change_name = ((opt={},cb) ->
  if !opt.name then return cb new Error "`opt.name` required"
  @name = opt.name
  @save cb
)
```

add the function name to the `model.AUTO_EXPOSE.methods` array

```coffeescript
model.AUTO_EXPOSE = {
  route: '/friends'
  methods: [
    'change_name'
  ]
}
```

now run it through the browser, it converts `req.query` into `opt`, runs the
method and returns the result to the browser

`http://localhost:10001/friends/:_id/change_name?method=post&name=Jose`

<img src="https://taky.s3.amazonaws.com/81gx7f0decob.png" width="250">

## globals
- `log` winston instance
- `db` mongojs instance
- `db.<Model>` (mongoose models loaded into `db`)
- `redis` ioredis instance
- `memcached` node-memcached instance
- `conf` configuration object
- `eve` eventemitter2 instance

## autoloaded
- models located in `./models`
- routes located in `./routes` are loaded using the base file name minus the
  extension as the path prefix
- files in `./cron` are automatically `required`

## bin generators
- `./crons/_create`
- `./models/_create`
- `./routes/_create`

