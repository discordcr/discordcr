require "json"
require "time/format"

module Discord
  module SnowflakeConverter
    def self.from_json(parser : JSON::PullParser) : UInt64
      str = parser.read_string_or_null
      str.not_nil!.to_u64
    end

    def self.to_json(value : UInt64, io : IO)
      io.puts(value.to_s)
    end
  end

  # Converts a value that may be a snowflake, but might also be nil, to a
  # UInt64.
  module MaybeSnowflakeConverter
    def self.from_json(parser : JSON::PullParser) : UInt64 | Nil
      str = parser.read_string_or_null

      if str
        str.to_u64
      else
        nil
      end
    end

    def self.to_json(value : UInt64 | Nil, io : IO)
      if value
        io.puts(value.to_s)
      else
        io.puts("null")
      end
    end
  end

  # Converts an array of strings to an array of UInt64s.
  module SnowflakeArrayConverter
    def self.from_json(parser : JSON::PullParser) : Array(UInt64)
      Array(String).new(parser).map &.to_u64
    end

    def self.to_json(value : Array(UInt64), io : IO)
      value.map(&.to_s).to_json(io)
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
      id: {type: UInt64, converter: SnowflakeConverter},
      discriminator: String,
      avatar: String
    )
  end

  struct Message
    JSON.mapping(
      type: UInt8 | Nil,
      content: String,
      id: {type: UInt64, converter: SnowflakeConverter},
      channel_id: {type: UInt64, converter: SnowflakeConverter},
      author: User,
      timestamp: {type: Time, converter: Time::Format::ISO_8601_DATE},
      tts: Bool,
      mention_everyone: Bool,
      mentions: Array(User)
    )
  end

  struct Channel
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: UInt8,
      guild_id: {type: UInt64 | Nil, converter: MaybeSnowflakeConverter},
      name: String | Nil,
      is_private: Bool | Nil,
      permission_overwrites: Array(Overwrite) | Nil,
      topic: String | Nil,
      last_message_id: {type: UInt64 | Nil, converter: MaybeSnowflakeConverter},
      bitrate: UInt32 | Nil,
      user_limit: UInt32 | Nil,
      recipients: Array(User) | Nil
    )
  end

  struct Overwrite
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: String,
      allow: UInt64,
      deny: UInt64
    )
  end

  struct EmbedThumbnail
    JSON.mapping(
      url: String,
      proxy_url: String,
      height: UInt32,
      width: UInt32
    )
  end

  struct EmbedProvider
    JSON.mapping(
      name: String,
      url: String
    )
  end

  struct Attachment
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      filename: String,
      size: UInt32,
      url: String,
      proxy_url: String,
      height: UInt32 | Nil,
      width: UInt32 | Nil
    )
  end

  struct VoiceState
    JSON.mapping(
      guild_id: {type: UInt64 | Nil, converter: MaybeSnowflakeConverter},
      channel_id: {type: UInt64, converter: SnowflakeConverter},
      user_id: {type: UInt64, converter: SnowflakeConverter},
      session_id: String,
      deaf: Bool,
      mute: Bool,
      self_deaf: Bool,
      self_mute: Bool,
      suppress: Bool
    )
  end

  struct Guild
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      icon: String | Nil,
      splash: String | Nil,
      owner_id: {type: UInt64, converter: SnowflakeConverter},
      region: String,
      afk_channel_id: {type: UInt64 | Nil, converter: MaybeSnowflakeConverter},
      afk_timeout: Int32 | Nil,
      embed_enabled: Bool | Nil,
      embed_channel_id: {type: UInt64 | Nil, converter: MaybeSnowflakeConverter},
      verification_level: UInt8,
      voice_states: Array(VoiceState),
      roles: Array(Role),
      emoji: {type: Array(Emoji), key: "emojis"},
      features: Array(String)
    )
  end

  struct UnavailableGuild
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      unavailable: Bool
    )
  end

  struct GuildEmbed
    JSON.mapping(
      enabled: Bool,
      channel_id: {type: UInt64, converter: SnowflakeConverter}
    )
  end

  struct GuildMember
    JSON.mapping(
      user: User,
      nick: String | Nil,
      roles: Array(Role),
      joined_at: {type: Time | Nil, converter: Time::Format::ISO_8601_DATE},
      deaf: Bool,
      mute: Bool
    )
  end

  struct Integration
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      type: String,
      enabled: Bool,
      syncing: Bool,
      role_id: {type: UInt64, converter: SnowflakeConverter},
      expire_behaviour: {type: UInt8, key: "expire_behavior"},
      expire_grace_period: Int32,
      user: User,
      account: IntegrationAccount,
      synced_at: {type: Time, converter: Time::EpochConverter}
    )
  end

  struct IntegrationAccount
    JSON.mapping(
      id: String,
      name: String
    )
  end

  struct Emoji
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
      require_colons: Bool,
      managed: Bool
    )
  end

  struct Role
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      colour: {type: UInt32, key: "color"},
      hoist: Bool,
      position: Int32,
      managed: Bool,
      mentionable: Bool
    )
  end
end
