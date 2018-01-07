require "./converters"
require "./user"

module Discord
  struct Webhook
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      guild_id: {type: UInt64?, converter: SnowflakeConverter},
      channel_id: {type: UInt64, converter: SnowflakeConverter},
      user: User?,
      name: String,
      avatar: String?,
      token: String
    )
  end
end
