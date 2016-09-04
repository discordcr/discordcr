require "./converters"
require "./user"
require "./channel"

module Discord
  module Gateway
    struct ReadyPayload
      JSON.mapping(
        v: UInt8,
        user: User,
        private_channels: Array(PrivateChannel),
        guilds: Array(UnavailableGuild),
        session_id: String
      )
    end

    struct HelloPayload
      JSON.mapping(
        heartbeat_interval: UInt32,
        _trace: Array(String)
      )
    end
  end
end
