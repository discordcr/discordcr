# This example is nearly the same as the normal ping example, but rather than simply
# responding with "Pong!", it also responds with the time it took to send the message.

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)

client.on_message_create do |payload|
  if payload.content.starts_with? "!ping"
    # We first create a new Message, and then we check how long it took to send the message by comparing it to the current time
    m = client.create_message(payload.channel_id, "Pong!")
    time = Time.utc_now - payload.timestamp
    client.edit_message(m.channel_id, m.id, "Pong! Time taken: #{time.total_milliseconds} ms.")
  end
end

client.run
