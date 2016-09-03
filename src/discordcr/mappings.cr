require "json"

module Discord
  module SnowflakeConverter
    def self.from_json(parser : JSON::PullParser) : UInt64
    end

    def self.to_json(value : String, io : IO)
    end
  end

  module REST
    # A response to the Get Gateway REST API call.
    struct GatewayResponse
      JSON.mapping(
        url: String
      )
    end
  end

  module Gateway
    # TODO: Expand this
    struct ReadyPayload
      JSON.mapping(
        v: UInt8
      )
    end

    struct MessageCreatePayload
      JSON.mapping(
        type: UInt8,
        content: String,
        id: String,
        author: User
      )
    end

    struct HelloPayload
      JSON.mapping(
        heartbeat_interval: UInt32,
        _trace: Array(String)
      )
    end
  end

  struct User
    JSON.mapping(
      username: String,
      id: String,
      discriminator: String,
      avatar: String
    )
  end
end
