require "./converters"
require "./user"
require "./channel"
require "./guild"

module Discord
  module Gateway
    struct ReadyPayload
      JSON.mapping(
        v: UInt8,
        user: User,
        private_channels: Array(PrivateChannel),
        guilds: Array(UnavailableGuild),
        session_id: String
      )
    end

    struct HelloPayload
      JSON.mapping(
        heartbeat_interval: UInt32,
        _trace: Array(String)
      )
    end

    struct GuildDeletePayload
      JSON.mapping(
        id: {type: UInt64, converter: SnowflakeConverter},
        unavailable: {type: Bool, nilable: true}
      )
    end

    struct GuildBanPayload
      JSON.mapping(
        username: String,
        id: {type: UInt64, converter: SnowflakeConverter},
        discriminator: String,
        avatar: String,
        bot: {type: Bool, nilable: true},
        guild_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct GuildEmojiUpdatePayload
      JSON.mapping(
        guild_id: {type: UInt64, converter: SnowflakeConverter},
        emoji: {type: Array(Emoji), key: "emojis"}
      )
    end
  end
end
