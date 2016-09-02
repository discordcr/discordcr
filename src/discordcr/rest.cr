require "http/client"

require "./mappings"

module Discordcr
  module REST
    def request(endpoint_key : Symbol, method : String, url : String | URI, headers : HTTP::Headers | Nil, body : String | Nil)
      headers["Authorization"] = @token
      HTTP::Client.exec(method: method, url: url, headers: headers, body: body, tls: true)
    end

    API_BASE = "https://discordapp.com/api/v6"

    GET = "get"

    def gateway
      response = request(
        :gateway,
        GET,
        API_BASE + "/gateway",
        HTTP::Headers.new,
        nil
      )

      puts response.body

      GatewayResponse.from_json(response.body_io)
    end
  end
end
