require "logger"

# The logger class is monkey patched to have a property for the IO.
class Logger
  property io
end

module Discord
  # The built in logger.
  LOGGER = Logger.new(STDOUT)
  LOGGER.progname = "discordcr"
end
