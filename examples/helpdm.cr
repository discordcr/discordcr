# This example will teach you explicitly how to send 
# a "help" message to a user who requests it via direct message 
# (dm) 

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)

# this event is fired each time a new message is sent to the a text channel to any guild that the bot is connected to. 
client.on_message_create do |payload|
  prefix = "!"
  if payload.content.starts_with? prefix + "help"
    client.create_message(client.create_dm(payload.author.id).id, "Help is on the way!")
  end
end

client.run
