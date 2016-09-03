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
end
