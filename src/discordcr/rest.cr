require "http/client"
require "openssl/ssl/context"

require "./mappings"
require "./version"

module Discord
  module REST
    SSL_CONTEXT = OpenSSL::SSL::Context::Client.new
    USER_AGENT  = "DiscordBot (https://github.com/meew0/discordcr, #{Discord::VERSION})"

    def request(endpoint_key : Symbol, method : String, url : String | URI, headers : HTTP::Headers, body : String | Nil)
      headers["Authorization"] = @token
      headers["User-Agent"] = USER_AGENT

      HTTP::Client.exec(method: method, url: url, headers: headers, body: body, tls: SSL_CONTEXT)
    end

    API_BASE = "https://discordapp.com/api/v6"

    def get_gateway
      response = request(
        :get_gateway,
        "GET",
        API_BASE + "/gateway",
        HTTP::Headers.new,
        nil
      )

      # TODO: Investigate failed nil assertion with body_io
      GatewayResponse.from_json(response.body)
    end

    def create_message(channel_id, content)
      response = request(
        :create_message,
        "POST",
        API_BASE + "/channels/#{channel_id}/messages",
        HTTP::Headers{"Content-Type" => "application/json"},
        {content: content}.to_json
      )

      Message.from_json(response.body)
    end
  end
end
