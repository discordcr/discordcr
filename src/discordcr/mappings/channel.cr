require "./converters"

module Discord
  struct Message
    JSON.mapping(
      type: {type: UInt8, nilable: true},
      content: String,
      id: {type: UInt64, converter: SnowflakeConverter},
      channel_id: {type: UInt64, converter: SnowflakeConverter},
      author: User,
      timestamp: {type: Time, converter: DATE_FORMAT},
      tts: Bool,
      mention_everyone: Bool,
      mentions: Array(User),
      mention_roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
      attachments: Array(Attachment),
      embeds: Array(Embed),
      pinned: {type: Bool, nilable: true}
    )
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
      type: UInt8,
      guild_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      name: {type: String, nilable: true},
      is_private: {type: Bool, nilable: true},
      permission_overwrites: {type: Array(Overwrite), nilable: true},
      topic: {type: String, nilable: true},
      last_message_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      bitrate: {type: UInt32, nilable: true},
      user_limit: {type: UInt32, nilable: true},
      recipients: {type: Array(User), nilable: true}
    )
  end

  struct PrivateChannel
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: UInt8,
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

  struct Embed
    JSON.mapping(
      title: {type: String, nilable: true},
      type: String,
      description: {type: String, nilable: true},
      url: String?,
      timestamp: {type: Time, converter: EmbedTimestampConverter, nilable: true},
      colour: {type: UInt32, key: "color", nilable: true},
      footer: {type: EmbedFooter, nilable: true},
      image: {type: EmbedImage, nilable: true},
      thumbnail: {type: EmbedThumbnail, nilable: true},
      video: {type: EmbedVideo, nilable: true},
      provider: {type: EmbedProvider, nilable: true},
      author: {type: EmbedAuthor, nilable: true},
      fields: {type: Array(EmbedField), nilable: true}
    )

    {% unless flag?(:correct_english) %}
      def color
        colour
      end
    {% end %}
  end

  struct EmbedThumbnail
    JSON.mapping(
      url: String,
      proxy_url: String,
      height: UInt32,
      width: UInt32
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
      url: {type: String, nilable: true}
    )
  end

  struct EmbedAuthor
    JSON.mapping(
      name: String,
      url: String,
      icon_url: String,
      proxy_icon_url: String
    )
  end

  struct EmbedFooter
    JSON.mapping(
      text: String,
      icon_url: String,
      proxy_icon_url: String
    )
  end

  struct EmbedField
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
      height: {type: UInt32, nilable: true},
      width: {type: UInt32, nilable: true}
    )
  end
end
