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

    # This one is special from simply Guild since it also has fields for members
    # and presences.
    struct GuildCreatePayload
      JSON.mapping(
        id: {type: UInt64, converter: SnowflakeConverter},
        name: String,
        icon: {type: String, nilable: true},
        splash: {type: String, nilable: true},
        owner_id: {type: UInt64, converter: SnowflakeConverter},
        region: String,
        afk_channel_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
        afk_timeout: {type: Int32, nilable: true},
        verification_level: UInt8,
        roles: Array(Role),
        emoji: {type: Array(Emoji), key: "emojis"},
        features: Array(String),
        large: Bool,
        voice_states: Array(VoiceState),
        unavailable: {type: Bool, nilable: true},
        member_count: Int32,
        members: Array(GuildMember),
        channels: Array(Channel),
        presences: Array(Presence)
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

    struct GuildIntegrationsUpdatePayload
      JSON.mapping(
        guild_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct GuildMemberAddPayload
      JSON.mapping(
        user: User,
        nick: {type: String, nilable: true},
        roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
        joined_at: {type: Time?, converter: Time::Format::ISO_8601_DATE},
        deaf: Bool,
        mute: Bool,
        guild_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct GuildMemberUpdatePayload
      JSON.mapping(
        user: User,
        roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
        guild_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct GuildMemberRemovePayload
      JSON.mapping(
        user: User,
        guild_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct GuildMembersChunkPayload
      JSON.mapping(
        guild_id: {type: UInt64, converter: SnowflakeConverter},
        members: Array(GuildMember)
      )
    end

    struct GuildRolePayload
      JSON.mapping(
        guild_id: {type: UInt64, converter: SnowflakeConverter},
        role: Role
      )
    end

    struct GuildRoleDeletePayload
      JSON.mapping(
        guild_id: {type: UInt64, converter: SnowflakeConverter},
        role_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct MessageDeletePayload
      JSON.mapping(
        id: {type: UInt64, converter: SnowflakeConverter},
        channel_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct MessageDeleteBulkPayload
      JSON.mapping(
        ids: {type: Array(UInt64), converter: SnowflakeArrayConverter},
        channel_id: {type: UInt64, converter: SnowflakeConverter}
      )
    end

    struct PresenceUpdatePayload
      JSON.mapping(
        user: PartialUser,
        roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
        game: {type: GamePlaying, nilable: true},
        nick: {type: String, nilable: true},
        guild_id: {type: UInt64, converter: SnowflakeConverter},
        status: String
      )
    end

    struct TypingStartPayload
      JSON.mapping(
        channel_id: {type: UInt64, converter: SnowflakeConverter},
        user_id: {type: UInt64, converter: SnowflakeConverter},
        timestamp: {type: Time, converter: Time::EpochConverter}
      )
    end

    struct VoiceServerUpdatePayload
      JSON.mapping(
        token: String,
        guild_id: {type: UInt64, converter: SnowflakeConverter},
        endpoint: String
      )
    end
  end
end
