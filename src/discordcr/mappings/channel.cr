require "./converters"

module Discord
  struct Message
    JSON.mapping(
      type: UInt8?,
      content: String,
      id: {type: UInt64, converter: SnowflakeConverter},
      channel_id: {type: UInt64, converter: SnowflakeConverter},
      author: User,
      timestamp: {type: Time, converter: Time::Format::ISO_8601_DATE},
      tts: Bool,
      mention_everyone: Bool,
      mentions: Array(User),
      mention_roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
      attachments: Array(Attachment),
      embeds: Array(Embed),
      nonce: {type: UInt64?, converter: MaybeSnowflakeConverter},
      pinned: Bool?
    )
  end

  struct Channel
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: UInt8,
      guild_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      name: String?,
      is_private: Bool?,
      permission_overwrites: Array(Overwrite)?,
      topic: String?,
      last_message_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      bitrate: UInt32?,
      user_limit: UInt32?,
      recipients: Array(User)?
    )
  end

  struct PrivateChannel
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      type: UInt8,
      recipients: Array(User),
      last_message_id: UInt64
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

  struct Embed
    JSON.mapping(
      title: String,
      type: String,
      description: String,
      url: String,
      thumbnail: EmbedThumbnail,
      provider: EmbedProvider
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
      height: UInt32?,
      width: UInt32?
    )
  end
end
