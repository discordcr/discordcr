require "./converters"

module Discord
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
      mentions: Array(User),
      mention_roles: {type: Array(UInt64), converter: SnowflakeArrayConverter},
      attachments: Array(Attachment),
      embeds: Array(Embed),
      nonce: {type: UInt64 | Nil, converter: MaybeSnowflakeConverter},
      pinned: Bool | Nil
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
      height: UInt32 | Nil,
      width: UInt32 | Nil
    )
  end
end
