require "json"
require "time/format"

module Discord
  module SnowflakeConverter
    def self.from_json(parser : JSON::PullParser) : UInt64
      str = parser.read_string_or_null
      str.not_nil!.to_u64
    end

    def self.to_json(value : UInt64, io : IO)
      io.puts(value.to_s)
    end
  end

  # Converts a value that may be a snowflake, but might also be nil, to a
  # UInt64.
  module MaybeSnowflakeConverter
    def self.from_json(parser : JSON::PullParser) : UInt64 | Nil
      str = parser.read_string_or_null

      if str
        str.to_u64
      else
        nil
      end
    end

    def self.to_json(value : UInt64 | Nil, io : IO)
      if value
        io.puts(value.to_s)
      else
        io.puts("null")
      end
    end
  end

  # Converts an array of strings to an array of UInt64s.
  module SnowflakeArrayConverter
    def self.from_json(parser : JSON::PullParser) : Array(UInt64)
      Array(String).new(parser).map &.to_u64
    end

    def self.to_json(value : Array(UInt64), io : IO)
      value.map(&.to_s).to_json(io)
    end
  end
end
