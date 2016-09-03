require "json"

module Discordcr
  module REST
    # A response to the Get Gateway REST API call.
    struct GatewayResponse
      JSON.mapping(
        url: String
      )
    end
  end

  struct GatewayPacket
    JSON.mapping(
      op: UInt8,
      d: JSON::Any,
      s: UInt32 | Nil,
      t: String | Nil
    )
  end

  struct MessageCreatePayload
    JSON.mapping(
      type: UInt8,
      content: String,
      id: String,
      author: User
    )
  end
end
