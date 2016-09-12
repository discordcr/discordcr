require "./converters"

module Discord
  struct User
    JSON.mapping(
      username: String,
      id: {type: UInt64, converter: SnowflakeConverter},
      discriminator: String,
      avatar: {type: String, nilable: true},
      email: {type: String, nilable: true},
      bot: {type: Bool, nilable: true}
    )
  end

  struct PartialUser
    JSON.mapping(
      username: {type: String, nilable: true},
      id: {type: UInt64, converter: SnowflakeConverter},
      discriminator: {type: String, nilable: true},
      avatar: {type: String, nilable: true},
      email: {type: String, nilable: true},
      bot: {type: Bool, nilable: true}
    )

    def full? : Bool
      !@username.nil? && !@discriminator.nil? && !@avatar.nil?
    end
  end

  struct UserGuild
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      icon: String,
      owner: Bool,
      permissions: UInt64
    )
  end

  struct Connection
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      type: String,
      revoked: Bool
    )
  end
end
