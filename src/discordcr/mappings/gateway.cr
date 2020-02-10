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

    struct ResumedPayload
      JSON.mapping(
        _trace: Array(String)
      )
    end

    struct IdentifyPacket
      def initialize(token, properties, large_threshold, compress, shard, intents)
        @op = Discord::Client::OP_IDENTIFY
        @d = IdentifyPayload.new(token, properties, large_threshold, compress, shard, intents)
      end

      JSON.mapping(
        op: Int32,
        d: IdentifyPayload
      )
    end

    struct IdentifyPayload
      def initialize(@token, @properties, @compress, @large_threshold, @shard, @intents)
      end

      JSON.mapping({
        token:           String,
        properties:      IdentifyProperties,
        compress:        Bool,
        large_threshold: Int32,
        shard:           Tuple(Int32, Int32)?,
        intents:         Intents?,
      })
    end

    struct IdentifyProperties
      def initialize(@os, @browser, @device, @referrer, @referring_domain)
      end

      JSON.mapping(
        os: {key: "$os", type: String},
        browser: {key: "$browser", type: String},
        device: {key: "$device", type: String},
        referrer: {key: "$referrer", type: String},
        referring_domain: {key: "$referring_domain", type: String}
      )
    end

    @[Flags]
    enum Intents
      Guilds                 = 1 << 0
      GuildMembers           = 1 << 1
      GuildBans              = 1 << 2
      GuildEmojis            = 1 << 3
      GuildIntegrations      = 1 << 4
      GuildWebhooks          = 1 << 5
      GuildInvites           = 1 << 6
      GuildVoiceStates       = 1 << 7
      GuildPresences         = 1 << 8
      GuildMessages          = 1 << 9
      GuildMessageReactions  = 1 << 10
      GuildMessageTyping     = 1 << 11
      DirectMessages         = 1 << 12
      DirectMessageReactions = 1 << 13
      DirectMessageTyping    = 1 << 14
    end

    struct ResumePacket
      def initialize(token, session_id, seq)
        @op = Discord::Client::OP_RESUME
        @d = ResumePayload.new(token, session_id, seq)
      end

      JSON.mapping(
        op: Int32,
        d: ResumePayload
      )
    end

    # :nodoc:
    struct ResumePayload
      def initialize(@token, @session_id, @seq)
      end

      JSON.mapping(
        token: String,
        session_id: String,
        seq: Int64
      )
    end

    struct StatusUpdatePacket
      def initialize(status, game, afk, since)
        @op = Discord::Client::OP_STATUS_UPDATE
        @d = StatusUpdatePayload.new(status, game, afk, since)
      end

      JSON.mapping(
        op: Int32,
        d: StatusUpdatePayload
      )
    end

    # :nodoc:
    struct StatusUpdatePayload
      def initialize(@status, @game, @afk, @since)
      end

      JSON.mapping(
        status: {type: String?, emit_null: true},
        game: {type: GamePlaying?, emit_null: true},
        afk: Bool,
        since: {type: Int64, nilable: true, emit_null: true}
      )
    end

    struct VoiceStateUpdatePacket
      def initialize(guild_id, channel_id, self_mute, self_deaf)
        @op = Discord::Client::OP_VOICE_STATE_UPDATE
        @d = VoiceStateUpdatePayload.new(guild_id, channel_id, self_mute, self_deaf)
      end

      JSON.mapping(
        op: Int32,
        d: VoiceStateUpdatePayload
      )
    end

    # :nodoc:
    struct VoiceStateUpdatePayload
      def initialize(@guild_id, @channel_id, @self_mute, @self_deaf)
      end

      JSON.mapping(
        guild_id: UInt64,
        channel_id: {type: UInt64?, emit_null: true},
        self_mute: Bool,
        self_deaf: Bool
      )
    end

    struct RequestGuildMembersPacket
      def initialize(guild_id, query, limit)
        @op = Discord::Client::OP_REQUEST_GUILD_MEMBERS
        @d = RequestGuildMembersPayload.new(guild_id, query, limit)
      end

      JSON.mapping(
        op: Int32,
        d: RequestGuildMembersPayload
      )
    end

    # :nodoc:
    struct RequestGuildMembersPayload
      def initialize(@guild_id, @query, @limit)
      end

      JSON.mapping(
        guild_id: UInt64,
        query: String,
        limit: Int32
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
        id: Snowflake,
        name: String,
        icon: String?,
        splash: String?,
        owner_id: Snowflake,
        region: String,
        afk_channel_id: Snowflake?,
        afk_timeout: Int32?,
        verification_level: UInt8,
        roles: Array(Role),
        emoji: {type: Array(Emoji), key: "emojis"},
        features: Array(String),
        large: Bool,
        voice_states: Array(VoiceState),
        unavailable: Bool?,
        member_count: Int32,
        members: Array(GuildMember),
        channels: Array(Channel),
        presences: Array(Presence),
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
    end

    struct GuildDeletePayload
      JSON.mapping(
        id: Snowflake,
        unavailable: Bool?
      )
    end

    struct GuildBanPayload
      JSON.mapping(
        user: User,
        guild_id: Snowflake
      )
    end

    struct GuildEmojiUpdatePayload
      JSON.mapping(
        guild_id: Snowflake,
        emoji: {type: Array(Emoji), key: "emojis"}
      )

      {% unless flag?(:correct_english) %}
        def emojis
          emoji
        end
      {% end %}
    end

    struct GuildIntegrationsUpdatePayload
      JSON.mapping(
        guild_id: Snowflake
      )
    end

    struct GuildMemberAddPayload
      JSON.mapping(
        user: User,
        nick: String?,
        roles: Array(Snowflake),
        joined_at: {type: Time?, converter: MaybeTimestampConverter},
        deaf: Bool,
        mute: Bool,
        guild_id: Snowflake
      )
    end

    struct GuildMemberUpdatePayload
      JSON.mapping(
        user: User,
        roles: Array(Snowflake),
        nick: {type: String, nilable: true},
        guild_id: Snowflake
      )
    end

    struct GuildMemberRemovePayload
      JSON.mapping(
        user: User,
        guild_id: Snowflake
      )
    end

    struct GuildMembersChunkPayload
      JSON.mapping(
        guild_id: Snowflake,
        members: Array(GuildMember)
      )
    end

    struct GuildRolePayload
      JSON.mapping(
        guild_id: Snowflake,
        role: Role
      )
    end

    struct GuildRoleDeletePayload
      JSON.mapping(
        guild_id: Snowflake,
        role_id: Snowflake
      )
    end

    struct MessageReactionPayload
      JSON.mapping(
        user_id: Snowflake,
        channel_id: Snowflake,
        message_id: Snowflake,
        guild_id: Snowflake?,
        emoji: ReactionEmoji
      )
    end

    struct MessageReactionRemoveAllPayload
      JSON.mapping(
        channel_id: Snowflake,
        message_id: Snowflake,
        guild_id: Snowflake?
      )
    end

    struct MessageReactionRemoveEmojiPayload
      JSON.mapping(
        channel_id: Snowflake,
        guild_id: Snowflake,
        message_id: Snowflake,
        emoji: ReactionEmoji
      )
    end

    struct MessageUpdatePayload
      JSON.mapping(
        type: UInt8?,
        content: String?,
        id: Snowflake,
        channel_id: Snowflake,
        guild_id: Snowflake?,
        author: User?,
        timestamp: {type: Time?, converter: MaybeTimestampConverter},
        tts: Bool?,
        mention_everyone: Bool?,
        mentions: Array(User)?,
        mention_roles: Array(Snowflake)?,
        attachments: Array(Attachment)?,
        embeds: Array(Embed)?,
        pinned: Bool?
      )
    end

    struct MessageDeletePayload
      JSON.mapping(
        id: Snowflake,
        channel_id: Snowflake,
        guild_id: Snowflake?
      )
    end

    struct MessageDeleteBulkPayload
      JSON.mapping(
        ids: Array(Snowflake),
        channel_id: Snowflake,
        guild_id: Snowflake?
      )
    end

    struct PresenceUpdatePayload
      JSON.mapping(
        user: PartialUser,
        roles: Array(Snowflake),
        game: GamePlaying?,
        nick: String?,
        guild_id: Snowflake,
        status: String
      )
    end

    struct TypingStartPayload
      JSON.mapping(
        channel_id: Snowflake,
        user_id: Snowflake,
        guild_id: Snowflake?,
        member: GuildMember?,
        timestamp: {type: Time, converter: Time::EpochConverter}
      )
    end

    struct VoiceServerUpdatePayload
      JSON.mapping(
        token: String,
        guild_id: Snowflake,
        endpoint: String
      )
    end

    struct WebhooksUpdatePayload
      JSON.mapping(
        guild_id: Snowflake,
        channel_id: Snowflake
      )
    end

    struct ChannelPinsUpdatePayload
      JSON.mapping(
        last_pin_timestamp: {type: Time?, converter: MaybeTimestampConverter},
        channel_id: Snowflake
      )
    end
  end
end
