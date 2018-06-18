require "./converters"

module Discord
  enum MessageType : UInt8
    Default              = 0
    RecipientAdd         = 1
    RecipientRemove      = 2
    Call                 = 3
    ChannelNameChange    = 4
    ChannelIconChange    = 5
    ChannelPinnedMessage = 6
    GuildMemberJoin      = 7
  end

  struct Message
    JSON.mapping(
      type: {type: MessageType, converter: MessageTypeConverter},
      content: String,
      id: {type: UInt64, converter: SnowflakeConverter},
      channel_id: {type: UInt64, converter: SnowflakeConverter},
      author: User,
      timestamp: {type: Time, converter: TimestampConverter},
      tts: Bool,
      mention_everyone: Bool,
      mentions: Array(User),
      mention_roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
      attachments: Array(Attachment),
      embeds: Array(Embed),
      pinned: Bool?,
      reactions: Array(Reaction)?,
      activity: Activity?
    )
  end

  enum ActivityType : UInt8
    Join        = 1
    Spectate    = 2
    Listen      = 3
    JoinRequest = 5
  end

  struct Activity
    JSON.mapping(
      type: ActivityType,
      party_id: String?
    )
  end

  enum ChannelType : UInt8
    GuildText = 0
    DM        = 1
    Voice     = 2
    GroupDM   = 3
  end

  struct Channel
    # :nodoc:
    def initialize(private_channel : PrivateChannel)
      @id = private_channel.id
      @type = private_channel.type
      @recipients = private_channel.recipients
      @last_message_id = private_channel.last_message_id
    end

    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: {type: ChannelType, converter: ChannelTypeConverter},
      guild_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      name: String?,
      permission_overwrites: Array(Overwrite)?,
      topic: String?,
      last_message_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      bitrate: UInt32?,
      user_limit: UInt32?,
      recipients: Array(User)?,
      nsfw: Bool?,
      icon: Bool?,
      owner_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      application_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      position: Int32?,
      parent_id: {type: UInt64?, converter: MaybeSnowflakeConverter}
    )
  end

  struct PrivateChannel
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: {type: ChannelType, converter: ChannelTypeConverter},
      recipients: Array(User),
      last_message_id: {type: UInt64?, converter: MaybeSnowflakeConverter}
    )
  end

  struct Overwrite
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: String,
      allow: Permissions,
      deny: Permissions
    )
  end

  struct Reaction
    JSON.mapping(
      emoji: ReactionEmoji,
      count: UInt32,
      me: Bool
    )
  end

  struct ReactionEmoji
    JSON.mapping(
      id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      name: String
    )
  end

  struct Embed
    def initialize(@title : String? = nil, @type : String = "rich",
                   @description : String? = nil, @url : String? = nil,
                   @timestamp : Time? = nil, @colour : UInt32? = nil,
                   @footer : EmbedFooter? = nil, @image : EmbedImage? = nil,
                   @thumbnail : EmbedThumbnail? = nil, @author : EmbedAuthor? = nil,
                   @fields : Array(EmbedField)? = nil)
    end

    JSON.mapping(
      title: String?,
      type: String,
      description: String?,
      url: String?,
      timestamp: {type: Time?, converter: TimestampConverter},
      colour: {type: UInt32?, key: "color"},
      footer: EmbedFooter?,
      image: EmbedImage?,
      thumbnail: EmbedThumbnail?,
      video: EmbedVideo?,
      provider: EmbedProvider?,
      author: EmbedAuthor?,
      fields: Array(EmbedField)?
    )

    {% unless flag?(:correct_english) %}
      def color
        colour
      end
    {% end %}
  end

  struct EmbedThumbnail
    def initialize(@url : String)
    end

    JSON.mapping(
      url: String,
      proxy_url: String?,
      height: UInt32?,
      width: UInt32?
    )
  end

  struct EmbedVideo
    JSON.mapping(
      url: String,
      height: UInt32,
      width: UInt32
    )
  end

  struct EmbedImage
    def initialize(@url : String)
    end

    JSON.mapping(
      url: String,
      proxy_url: String?,
      height: UInt32?,
      width: UInt32?
    )
  end

  struct EmbedProvider
    JSON.mapping(
      name: String,
      url: String?
    )
  end

  struct EmbedAuthor
    def initialize(@name : String? = nil, @url : String? = nil, @icon_url : String? = nil)
    end

    JSON.mapping(
      name: String?,
      url: String?,
      icon_url: String?,
      proxy_icon_url: String?
    )
  end

  struct EmbedFooter
    def initialize(@text : String? = nil, @icon_url : String? = nil)
    end

    JSON.mapping(
      text: String?,
      icon_url: String?,
      proxy_icon_url: String?
    )
  end

  struct EmbedField
    def initialize(@name : String, @value : String, @inline : Bool = false)
    end

    JSON.mapping(
      name: String,
      value: String,
      inline: Bool
    )
  end

  struct Attachment
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      filename: String,
      size: UInt32,
      url: String,
      proxy_url: String,
      height: UInt32?,
      width: UInt32?
    )
  end
end
