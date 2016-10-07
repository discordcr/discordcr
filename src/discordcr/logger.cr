require "logger"

module Discord
  # The built in logger.
  LOGGER = Logger.new(STDOUT)
  LOGGER.progname = "discordcr"
end
