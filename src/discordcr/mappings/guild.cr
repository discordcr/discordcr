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
      @widget_channel_id = payload.widget_channel_id
      @default_message_notifications = payload.default_message_notifications
      @explicit_content_filter = payload.explicit_content_filter
      @system_channel_id = payload.system_channel_id
    end

    JSON.mapping(
      id: Snowflake,
      name: String,
      icon: String?,
      splash: String?,
      owner_id: Snowflake,
      region: String,
      afk_channel_id: Snowflake?,
      afk_timeout: Int32?,
      embed_enabled: Bool?,
      embed_channel_id: Snowflake?,
      verification_level: UInt8,
      roles: Array(Role),
      emoji: {type: Array(Emoji), key: "emojis"},
      features: Array(String),
      widget_enabled: {type: Bool, nilable: true},
      widget_channel_id: Snowflake?,
      default_message_notifications: UInt8,
      explicit_content_filter: UInt8,
      system_channel_id: Snowflake?
    )

    {% unless flag?(:correct_english) %}
      def emojis
        emoji
      end
    {% end %}

    # Produces a CDN URL to this guild's icon in the given `format` and `size`,
    # or `nil` if no icon is set.
    def icon_url(format : CDN::GuildIconFormat = CDN::GuildIconFormat::WebP,
                 size : Int32 = 128)
      if icon = @icon
        CDN.guild_icon(id, icon, format, size)
      end
    end

    # Produces a CDN URL to this guild's splash in the given `format` and `size`,
    # or `nil` if no splash is set.
    def splash_url(format : CDN::GuildSplashFormat = CDN::GuildSplashFormat::WebP,
                   size : Int32 = 128)
      if splash = @splash
        CDN.guild_splash(id, splash, format, size)
      end
    end
  end

  struct UnavailableGuild
    JSON.mapping(
      id: Snowflake,
      unavailable: Bool
    )
  end

  struct GuildEmbed
    JSON.mapping(
      enabled: Bool,
      channel_id: Snowflake?
    )
  end

  struct GuildMember
    # :nodoc:
    def initialize(user : User, partial_member : PartialGuildMember)
      @user = user
      @roles = partial_member.roles
      @nick = partial_member.nick
      @joined_at = partial_member.joined_at
      @mute = partial_member.mute
      @deaf = partial_member.deaf
    end

    # :nodoc:
    def initialize(payload : Gateway::GuildMemberAddPayload | GuildMember, roles : Array(Snowflake), nick : String?)
      initialize(payload)
      @nick = nick
      @roles = roles
    end

    # :nodoc:
    def initialize(payload : Gateway::GuildMemberAddPayload | GuildMember)
      @user = payload.user
      @nick = payload.nick
      @roles = payload.roles
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
      nick: String?,
      roles: Array(Snowflake),
      joined_at: {type: Time?, converter: MaybeTimestampConverter},
      deaf: Bool?,
      mute: Bool?
    )

    # Produces a string to mention this member in a message
    def mention
      if nick
        "<@!#{user.id}>"
      else
        "<@#{user.id}>"
      end
    end
  end

  struct PartialGuildMember
    JSON.mapping(
      nick: String?,
      roles: Array(Snowflake),
      joined_at: {type: Time, converter: TimestampConverter},
      deaf: Bool,
      mute: Bool
    )
  end

  struct Integration
    JSON.mapping(
      id: Snowflake,
      name: String,
      type: String,
      enabled: Bool,
      syncing: Bool,
      role_id: Snowflake,
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
      id: Snowflake,
      name: String,
      roles: Array(Snowflake),
      require_colons: Bool,
      managed: Bool,
      animated: Bool
    )

    # Produces a CDN URL to this emoji's image in the given `size`. Will return
    # a PNG, or GIF if the emoji is animated.
    def image_url(size : Int32 = 128)
      if animated
        image_url(:gif, size)
      else
        image_url(:png, size)
      end
    end

    # Produces a CDN URL to this emoji's image in the given `format` and `size`
    def image_url(format : CDN::CustomEmojiFormat, size : Int32 = 128)
      CDN.custom_emoji(id, format, size)
    end

    # Produces a string to mention this emoji in a message
    def mention
      if animated
        "<a:#{name}:#{id}>"
      else
        "<:#{name}:#{id}>"
      end
    end
  end

  struct Role
    JSON.mapping(
      id: Snowflake,
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

    # Produces a string to mention this role in a message
    def mention
      "<@&#{id}>"
    end
  end

  struct GuildBan
    JSON.mapping(
      user: User,
      reason: String?
    )
  end

  struct GamePlaying
    def initialize(@name = nil, @type = nil, @url = nil)
    end

    JSON.mapping(
      name: String?,
      type: Int64? | String?,
      url: String?
    )
  end

  struct Presence
    JSON.mapping(
      user: PartialUser,
      game: GamePlaying?,
      status: String
    )
  end
end
