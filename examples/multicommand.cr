# multicommand.cr is an example that uses a simple command "dispatcher"
# via a case statement.
# This example features a few commands:
# » !help        ==> sends a dm (direct message) to the user
#                    with information
# » !about       ==> prints about information in a code block
# » !echo <args> ==> echos args
# » !date        ==> prints the current date

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)

client.on_message_create do |payload|
  prefix = "!"
  command = payload.content
  case command
  when prefix + "help"
    client.create_message(client.create_dm(payload.author.id).id, "Help is on the way!")
  when prefix + "about"
    block = ["```\n", "Bot developed by discordcr\n", "```"]
    client.create_message(payload.channel_id, block.join(""))
  when .starts_with? prefix + "echo"
    # !echo is a good example of a command with arguments (suffix)
    suffix = command.split(' ')[1..-1].join(" ")
    client.create_message(payload.channel_id, suffix)
  when prefix + "date"
    client.create_message(payload.channel_id, Time.now.to_s("%D"))
  end
end

client.run
