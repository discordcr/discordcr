require "./converters"

module Discord
  struct VoiceState
    JSON.mapping(
      guild_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      channel_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
      user_id: {type: UInt64, converter: SnowflakeConverter},
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
      custom: {type: Bool, nilable: true},
      vip: Bool,
      optimal: Bool
    )
  end
end
