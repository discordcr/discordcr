require "./converters"
require "./user"

module Discord
  struct Invite
    JSON.mapping(
      code: String,
      guild: InviteGuild,
      channel: InviteChannel
    )
  end

  struct InviteMetadata
    JSON.mapping(
      code: String,
      guild: InviteGuild,
      channel: InviteChannel,
      inviter: User,
      users: UInt32,
      max_uses: UInt32,
      max_age: UInt32,
      temporary: Bool,
      created_at: {type: Time, converter: Time::Format::ISO_8601_DATE},
      revoked: Bool
    )
  end

  struct InviteGuild
    JSON.mapping(
      id: {type: UInt64, converter: SnowflakeConverter},
      name: String,
      splash_hash: {type: String, nilable: true}
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
