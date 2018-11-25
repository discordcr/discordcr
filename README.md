[![docs](https://img.shields.io/badge/docs-latest-green.svg?style=flat-square)](https://meew0.github.io/discordcr/doc/v0.4.0/)

# discordcr

(The "cr" stands for "creative name".)

discordcr is a minimalist [Discord](https://discordapp.com/) API library for
[Crystal](https://crystal-lang.org/), designed to be a complement to
[discordrb](https://github.com/meew0/discordrb) for users who want more control
and performance and who care less about ease-of-use.

discordcr isn't designed for beginners to the Discord API - while experience
with making bots isn't *required*, it's certainly recommended. If you feel
overwhelmed by the complex documentation, try
[discordrb](https://github.com/meew0/discordrb) first and then check back.

Unlike many other libs which handle a lot of stuff, like caching or resolving,
themselves automatically, discordcr requires the user to do such things
manually. It also doesn't provide any advanced abstractions for REST calls;
the methods perform the HTTP request with the given data but nothing else.
This means that the user has full control over them, but also full
responsibility. discordcr does not support user accounts; it may work but
likely doesn't.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  discordcr:
    github: meew0/discordcr
```

## Usage

An example bot can be found
[here](https://github.com/meew0/discordcr/blob/master/examples/ping.cr). More
examples will come in the future.

A short overview of library structure: the `Client` class includes the `REST`
module, which handles the REST parts of Discord's API; the `Client` itself
handles the gateway, i. e. the interactive parts such as receiving messages. It
is possible to use only the REST parts by never calling the `#run` method on a
`Client`, which is what does the actual gateway connection.

The example linked above has an example of an event (`on_message_create`) that
is called through the gateway, and of a REST call (`client.create_message`).
Other gateway events and REST calls work much in the same way - see the
documentation for what specific events and REST calls do.

Caching is done using a separate `Cache` class that needs to be added into
clients manually:

```cr
client = Discord::Client.new # ...
cache = Discord::Cache.new(client)
client.cache = cache
```

Resolution requests for objects can now be done on the `cache` object instead of
directly over REST, this ensures that if an object is needed more than once
there will still only be one request to Discord. (There may even be no request
at all, if the requested data has already been obtained over the gateway.)
An example of how to use the cache once it has been instantiated:

```cr
# Get the username of the user with ID 66237334693085184
user = cache.resolve_user(66237334693085184_u64)
user = cache.resolve_user(66237334693085184_u64) # won't do a request to Discord
puts user.username
```

Apart from this, API documentation is also available, at
https://meew0.github.io/discordcr/doc/v0.4.0/.

## Contributing

1. Fork it (https://github.com/meew0/discordcr/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [meew0](https://github.com/meew0) - creator, maintainer
- [RX14](https://github.com/RX14) - Crystal expert, maintainer
