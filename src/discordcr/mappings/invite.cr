require "./converters"

module Discord
  struct InviteGuild
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      splash_hash: String?
    )
  end

  struct InviteChannel
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      type: UInt8
    )
  end
end
