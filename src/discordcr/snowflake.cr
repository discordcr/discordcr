module Discord
  DISCORD_EPOCH = 1420070400000_u64

  # Struct representing a Discord ID
  struct Snowflake
    include Comparable(Snowflake)
    include Comparable(UInt64)

    getter value : UInt64

    def self.new(string : String)
      new(string.to_u64)
    end

    def self.new(parser : JSON::PullParser)
      string = parser.read_string
      new(string.to_u64)
    end

    # Creates a `Snowflake` embedded with the given timestamp
    def self.new(time : Time)
      ms = time.epoch_ms.to_u64
      value = (ms - DISCORD_EPOCH) << 22
      new(value)
    end

    def initialize(@value : UInt64)
    end

    # Compatibility with UInt64 API
    def to_u64
      @value
    end

    def to_s(io : IO)
      io << @value
    end

    # The time at which this snowflake was created
    def creation_time
      ms = (value >> 22) + DISCORD_EPOCH
      Time.epoch_ms(ms)
    end

    def to_json(builder : JSON::Builder)
      builder.scalar value.to_s
    end

    def <=>(other : Snowflake)
      value <=> other.value
    end

    def <=>(int : UInt64)
      value <=> int
    end
  end
end
