require "http/client"
require "openssl/ssl/context"

require "./mappings"

module Discordcr
  module REST
    SSL_CONTEXT = OpenSSL::SSL::Context::Client.new

    def request(endpoint_key : Symbol, method : String, url : String | URI, headers : HTTP::Headers, body : String | Nil)
      headers["Authorization"] = @token
      HTTP::Client.exec(method: method, url: url, headers: headers, body: body, tls: SSL_CONTEXT)
    end

    API_BASE = "https://discordapp.com/api/v6"

    GET = "GET"
    POST = "POST"

    def gateway
      response = request(
        :gateway,
        GET,
        API_BASE + "/gateway",
        HTTP::Headers.new,
        nil
      )

      # TODO: Investigate failed nil assertion with body_io
      GatewayResponse.from_json(response.body)
    end

    def send_message(channel_id, content)
      response = request(
        :send_message,
        POST,
        API_BASE + "/channels/#{channel_id}/messages",
        HTTP::Headers{ "Content-Type" => "application/json" },
        { content: content }.to_json
      )
    end
  end
end
