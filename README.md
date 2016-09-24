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
manually. It also doesn't provide any sort of abstractions for REST calls,
the user has full control over them, but also full responsibility. discordcr
does not support user accounts; it may work but likely doesn't.

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

Documentation is available too but needs to be manually compiled locally.
Download the repo and run `crystal doc` in its folder, then the `doc` folder
will have the documentation to view.

## Contributing

1. Fork it (https://github.com/meew0/discordcr/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [meew0](https://github.com/meew0) - creator, maintainer
- [RX14](https://github.com/RX14) - Crystal expert, maintainer
