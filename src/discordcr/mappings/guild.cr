require "./converters"
require "./voice"

module Discord
  struct Guild
    # :nodoc:
    def initialize(payload : Gateway::GuildCreatePayload)
      @id = payload.id
      @name = payload.name
      @icon = payload.icon
      @splash = payload.splash
      @owner_id = payload.owner_id
      @region = payload.region
      @afk_channel_id = payload.afk_channel_id
      @afk_timeout = payload.afk_timeout
      @verification_level = payload.verification_level
      @roles = payload.roles
      @emoji = payload.emoji
      @features = payload.features
    end

    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      icon: {type: String, nilable: true},
      splash: {type: String, nilable: true},
      owner_id: {type: UInt64, converter: SnowflakeConverter},
      region: String,
      afk_channel_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      afk_timeout: {type: Int32, nilable: true},
      embed_enabled: {type: Bool, nilable: true},
      embed_channel_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      verification_level: UInt8,
      roles: Array(Role),
      emoji: {type: Array(Emoji), key: "emojis"},
      features: Array(String)
    )

    {% unless flag?(:correct_english) %}
      def emojis
        emoji
      end
    {% end %}
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
    # :nodoc:
    def initialize(payload : Gateway::GuildMemberAddPayload | GuildMember, roles : Array(UInt64)? = nil)
      @user = payload.user
      @nick = payload.nick
      @roles = roles || payload.roles
      @joined_at = payload.joined_at
      @deaf = payload.deaf
      @mute = payload.mute
    end

    # :nodoc:
    def initialize(payload : Gateway::PresenceUpdatePayload)
      @user = User.new(payload.user)
      @nick = payload.nick
      @roles = payload.roles
      # Presence updates have no joined_at or deaf/mute, thanks Discord
    end

    JSON.mapping(
      user: User,
      nick: {type: String, nilable: true},
      roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
      joined_at: {type: Time?, converter: Time::Format::ISO_8601_DATE},
      deaf: {type: Bool, nilable: true},
      mute: {type: Bool, nilable: true}
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

    {% unless flag?(:correct_english) %}
      def expire_behavior
        expire_behaviour
      end
    {% end %}
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
      permissions: Permissions,
      colour: {type: UInt32, key: "color"},
      hoist: Bool,
      position: Int32,
      managed: Bool,
      mentionable: Bool
    )

    {% unless flag?(:correct_english) %}
      def color
        colour
      end
    {% end %}
  end

  struct GamePlaying
    def initialize(@name = nil, @type = nil, @url = nil)
    end

    JSON.mapping(
      name: {type: String, nilable: true},
      type: {type: Int64 | String, nilable: true},
      url: {type: String, nilable: true}
    )
  end

  struct Presence
    JSON.mapping(
      user: PartialUser,
      game: {type: GamePlaying, nilable: true},
      status: String
    )
  end
end
