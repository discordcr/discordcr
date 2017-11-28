module Discord::REST
  # Enum for `parent_id` null significance in
  # `REST#modify_guild_channel_positions`.
  enum ChannelParent
    None
    Unchanged
  end
end
