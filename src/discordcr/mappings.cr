require "json"

module Discordcr
  module REST
    # A response to the Get Gateway REST API call.
    class GatewayResponse
      JSON.mapping (
        url: String
      )
    end
  end
end
