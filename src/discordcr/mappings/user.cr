require "./converters"

module Discord
  struct User
    JSON.mapping(
      username: String,
      id: {type: UInt64, converter: SnowflakeConverter},
      discriminator: String,
      avatar: String
    )
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
