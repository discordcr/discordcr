require "./converters"

module Discord
  struct User
    # :nodoc:
    def initialize(partial : PartialUser)
      @username = partial.username.not_nil!
      @id = partial.id
      @discriminator = partial.discriminator.not_nil!
      @avatar = partial.avatar
      @email = partial.email
      @bot = partial.bot
    end

    JSON.mapping(
      username: String,
      id: Snowflake,
      discriminator: String,
      avatar: String?,
      email: String?,
      bot: Bool?,
      mfa_enabled: Bool?,
      verified: Bool?
    )
  end

  struct PartialUser
    JSON.mapping(
      username: String?,
      id: Snowflake,
      discriminator: String?,
      avatar: String?,
      email: String?,
      bot: Bool?
    )

    def full? : Bool
      !@username.nil? && !@discriminator.nil? && !@avatar.nil?
    end
  end

  struct UserGuild
    JSON.mapping(
      id: Snowflake,
      name: String,
      icon: String?,
      owner: Bool,
      permissions: Permissions
    )
  end

  struct Connection
    JSON.mapping(
      id: Snowflake,
      name: String,
      type: String,
      revoked: Bool
    )
  end
end
