require "http/client"
require "openssl/ssl/context"

require "./mappings/*"
require "./version"

module Discord
  module REST
    SSL_CONTEXT = OpenSSL::SSL::Context::Client.new
    USER_AGENT  = "DiscordBot (https://github.com/meew0/discordcr, #{Discord::VERSION})"
    API_BASE = "https://discordapp.com/api/v6"

    def request(endpoint_key : Symbol, method : String, path : String, headers : HTTP::Headers, body : String?)
      headers["Authorization"] = @token
      headers["User-Agent"] = USER_AGENT

      HTTP::Client.exec(method: method, url: API_BASE + path, headers: headers, body: body, tls: SSL_CONTEXT)
    end

    def get_gateway
      response = request(
        :get_gateway,
        "GET",
        "/gateway",
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
        "/channels/#{channel_id}/messages",
        HTTP::Headers{"Content-Type" => "application/json"},
        {content: content}.to_json
      )

      Message.from_json(response.body)
    end
  end
end
