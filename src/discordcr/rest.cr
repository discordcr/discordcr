require "http/client"
require "openssl/ssl/context"

require "./mappings"

module Discordcr
  module REST
    SSL_CONTEXT = OpenSSL::SSL::Context::Client.new

    def request(endpoint_key : Symbol, method : String, url : String | URI, headers : HTTP::Headers | Nil, body : String | Nil)
      HTTP::Client.exec(method: method, url: url, headers: headers, body: body, tls: SSL_CONTEXT)
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
