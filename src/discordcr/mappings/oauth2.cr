require "./converters"
require "./user"

module Discord
  # An OAuth2 application, as registered with Discord, that can hold
  # information about a `Client`'s associated bot user account and owner,
  # among other OAuth2 properties.
  struct OAuth2Application
    JSON.mapping({
      id:                     Snowflake,
      name:                   String,
      icon:                   String?,
      description:            String?,
      rpc_origins:            Array(String)?,
      bot_public:             Bool,
      bot_require_code_grant: Bool,
      owner:                  User,
    })
  end
end
