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
      d: Nil,
      s: UInt32 | Nil,
      t: String | Nil
    )
end
