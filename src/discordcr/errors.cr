require "http/client/response"

module Discord
  # This exception is raised in `REST#request` when a request fails.
  class StatusException < Exception
    getter response : HTTP::Client::Response

    def initialize(@response : HTTP::Client::Response)
    end

    # The status code of the response that caused this exception, for example
    # 500 or 418.
    def status_code : Int32
      @response.status_code
    end

    # The status message of the response that caused this exception, for example
    # "Internal Server Error" or "I'm A Teapot".
    def status_message : String
      @response.status_message
    end

    def message
      "#{@response.status_code} #{@response.status_message}"
    end

    def to_s(io)
      io << @response.status_code << " " << @response.status_message
    end
  end
end
