require "json"
require "time/format"

module Discord
  # :nodoc:
  module TimestampConverter
    def self.from_json(parser : JSON::PullParser)
      time_str = parser.read_string

      begin
        Time::Format.new("%FT%T.%6N%:z").parse(time_str)
      rescue Time::Format::Error
        Time::Format.new("%FT%T%:z").parse(time_str)
      end
    end

    def self.to_json(value : Time, builder : JSON::Builder)
      Time::Format.new("%FT%T.%6N%:z").to_json(value, builder)
    end
  end

  # :nodoc:
  module MaybeTimestampConverter
    def self.from_json(parser : JSON::PullParser)
      if parser.kind.null?
        parser.read_null
        return nil
      end
      TimestampConverter.from_json(parser)
    end

    def self.to_json(value : Time?, builder : JSON::Builder)
      if value
        TimestampConverter.to_json(value, builder)
      else
        builder.null
      end
    end
  end
end
