require "http/client/response"
require "json"

module Discord
  # This exception is raised in `REST#request` when a request fails in general,
  # without returning a special error response.
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

  # An API error response.
  struct APIError
    JSON.mapping(
      code: Int32,
      message: String
    )
  end

  # This exception is raised in `REST#request` when a request fails with an
  # API error response that has a code and a descriptive message.
  class CodeException < StatusException
    getter error : APIError

    def initialize(@response : HTTP::Client::Response, @error : APIError)
    end

    # The API error code that was returned by Discord, for example 20001 or
    # 50016.
    def error_code : Int32
      @error.code
    end

    # The API error message that was returned by Discord, for example "Bots
    # cannot use this endpoint" or "Provided too few or too many messages to
    # delete. Must provide at least 2 and fewer than 100 messages to delete.".
    def error_message : String
      @error.message
    end

    def message
      "#{@response.status_code} #{@response.status_message}: Code #{@error.code} - #{@error.message}"
    end

    def to_s(io)
      io << @response.status_code << " " << @response.status_message << ": Code " << @error.code << " - " << @error.message
    end
  end
end
