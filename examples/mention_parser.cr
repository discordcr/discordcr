# This example demonstrates usage of `Discord::Mention.parse` to parse
# and handle different kinds of mentions appearing in a message.

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm")

client.on_message_create do |payload|
  next unless payload.content.starts_with?("parse:")

  mentions = String.build do |string|
    index = 0
    Discord::Mention.parse(payload.content) do |mention|
      index += 1
      string << "`[" << index << " @ " << mention.start << "]` "
      case mention
      when Discord::Mention::User
        string.puts "**User:** #{mention.id}"
      when Discord::Mention::Role
        string.puts "**Role:** #{mention.id}"
      when Discord::Mention::Channel
        string.puts "**Channel:** #{mention.id}"
      when Discord::Mention::Emoji
        string << "**Emoji:** #{mention.name} #{mention.id}"
        string << " (animated)" if mention.animated
        string.puts
      when Discord::Mention::Everyone
        string.puts "**Everyone**"
      when Discord::Mention::Here
        string.puts "**Here**"
      end
    end
  end

  mentions = "no mentions found in your message" if mentions.empty?

  begin
    client.create_message(
      payload.channel_id,
      mentions)
  rescue ex
    client.create_message(
      payload.channel_id,
      "`#{ex.inspect}`")
    raise ex
  end
end

client.run
