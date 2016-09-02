require "http/client"

module Discordcr
  module REST
    def request(endpoint_key : Symbol, method : String, url : String | URI, headers : HTTP::Headers | Nil, body : String | Nil)
      HTTP::Client.exec(method: method, url: url, headers: headers, body: body, tls: true)
    end
  end
end
