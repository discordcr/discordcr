require "./converters"

module Discord
  module Gateway
    # TODO: Expand this
    struct ReadyPayload
      JSON.mapping(
        v: UInt8
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
