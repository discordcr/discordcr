require "./converters"

module Discord
  struct VoiceState
    JSON.mapping(
      guild_id: Snowflake?,
      channel_id: Snowflake?,
      user_id: Snowflake,
      member: GuildMember?,
      session_id: String,
      deaf: Bool,
      mute: Bool,
      self_deaf: Bool,
      self_mute: Bool,
      suppress: Bool
    )
  end

  struct VoiceRegion
    JSON.mapping(
      id: String,
      name: String,
      sample_hostname: String,
      sample_port: UInt16,
      custom: Bool?,
      vip: Bool,
      optimal: Bool
    )
  end
end
