require "./converters"

module Discord
  struct VoiceState
    JSON.mapping(
      guild_id: {type: UInt64 | Nil, converter: MaybeSnowflakeConverter},
      channel_id: {type: UInt64, converter: SnowflakeConverter},
      user_id: {type: UInt64, converter: SnowflakeConverter},
      session_id: String,
      deaf: Bool,
      mute: Bool,
      self_deaf: Bool,
      self_mute: Bool,
      suppress: Bool
    )
  end
end
