require "./converters"
require "./user"

module Discord
  struct Webhook
    JSON.mapping(
      id: Snowflake,
      guild_id: Snowflake?,
      channel_id: Snowflake,
      user: User?,
      name: String,
      avatar: String?,
      token: String
    )
  end
end
