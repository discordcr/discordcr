# This simple example bot replies to every "!ping" message with "Pong!".

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)

client.on_message_create do |payload|
  if payload.content.starts_with? "!ping"
    client.create_message(payload.channel_id, "Pong!")
  end
end

client.run
