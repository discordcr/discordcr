require "./converters"
require "./voice"

module Discord
  struct Guild
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      icon: String?,
      splash: String?,
      owner_id: {type: UInt64, converter: SnowflakeConverter},
      region: String,
      afk_channel_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      afk_timeout: Int32?,
      embed_enabled: Bool?,
      embed_channel_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
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
      nick: String?,
      roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
      joined_at: {type: Time?, converter: Time::Format::ISO_8601_DATE},
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
