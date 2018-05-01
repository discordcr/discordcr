module Discord::Mention
  record User, id : UInt64, start : Int32, size : Int32

  record Role, id : UInt64, start : Int32, size : Int32

  record Channel, id : UInt64, start : Int32, size : Int32

  record Emoji, animated : Bool, name : String, id : UInt64, start : Int32, size : Int32

  record Everyone, start : Int32 do
    def size
      9
    end
  end

  record Here, start : Int32 do
    def size
      5
    end
  end

  alias MentionType = User | Role | Channel | Emoji | Everyone | Here

  # Returns an array of mentions found in a string
  def self.parse(string : String)
    Parser.new(string).parse
  end

  # Parses a string for mentions, yielding for each mention found
  def self.parse(string : String, &block : MentionType ->)
    Parser.new(string).parse(&block)
  end

  # :nodoc:
  class Parser
    def initialize(@string : String)
      @reader = Char::Reader.new string
    end

    delegate has_next?, pos, current_char, next_char, peek_next_char, to: @reader

    def parse(&block : MentionType ->)
      while has_next?
        start = pos
        animated = false

        case current_char
        when '<'
          case next_char
          when '@'
            case peek_next_char
            when '&'
              next_char # Skip role mention indicator

              if next_char.ascii_number?
                snowflake = scan_snowflake(pos)
                yield Role.new(snowflake, start, pos - start) if has_next? && current_char == '>'
              end
            when .ascii_number?, '!'
              next_char                        # Skip mention indicator
              next_char if current_char == '!' # Skip optional nickname indicator

              if current_char.ascii_number?
                snowflake = scan_snowflake(pos)
                yield User.new(snowflake, start, pos - start + 1) if current_char == '>'
              end
            end
          when '#'
            next_char # Skip channel mention indicator

            if peek_next_char.ascii_number?
              snowflake = scan_snowflake(pos)
              yield Channel.new(snowflake, start, pos - start + 1) if current_char == '>'
            end
          when ':', 'a'
            if current_char == 'a'
              next unless peek_next_char == ':'
              animated = true
              next_char
            end
            next_char

            name = scan_word(pos)
            if current_char == ':' && peek_next_char.ascii_number?
              next_char
              snowflake = scan_snowflake(pos)
              yield Emoji.new(animated, name, snowflake, start, pos - start + 1) if current_char == '>'
            end
          end
        when '@'
          word = scan_word(pos)
          case word
          when "@everyone"
            yield Everyone.new(start)
          when "@here"
            yield Here.new(start)
          end
        else
          next_char
        end
      end
    end

    def parse
      results = [] of MentionType
      parse { |mention| results << mention }
      results
    end

    private def scan_snowflake(start)
      while next_char.ascii_number?
        # Nothing to do
      end
      @string[start..pos - 1].to_u64
    end

    private def scan_word(start)
      while has_next?
        case next_char
        when .ascii_letter?, .ascii_number?
          # Nothing to do
        else
          break
        end
      end
      @string[start..pos - 1]
    end
  end
end
