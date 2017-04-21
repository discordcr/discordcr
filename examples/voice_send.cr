# This is a simple music bot that can connect to a voice channel and play back
# some music in DCA format. It demonstrates how to use VoiceClient and
# DCAParser.
#
# For more information on the DCA file format, see
# https://github.com/bwmarrin/dca.

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)

# ID of the current user, required to create a voice client
current_user_id = nil

# The ID of the (text) channel in which the connect command was run, so the
# "Voice connected." message is sent to the correct channel
connect_channel_id = nil

# Where the created voice client will eventually be stored
voice_client = nil

client.on_ready do |payload|
  current_user_id = payload.user.id
end

client.on_message_create do |payload|
  if payload.content.starts_with? "!connect "
    # Used as:
    # !connect <guild ID> <channel ID>

    # Parse the command arguments
    ids = payload.content[9..-1].split(' ').map(&.to_u64)

    client.create_message(payload.channel_id, "Connecting...")
    connect_channel_id = payload.channel_id
    client.voice_state_update(ids[0].to_u64, ids[1].to_u64, false, false)
  elsif payload.content.starts_with? "!play_dca "
    # Used as:
    # !play_dca <filename>
    #
    # Make sure the DCA file you play back is valid according to the spec
    # (including metadata), otherwise playback will fail.

    unless voice_client
      client.create_message(payload.channel_id, "Voice client is nil!")
      next
    end

    filename = payload.content[10..-1]
    file = File.open(filename)

    # The DCAParser class handles parsing of the DCA file. It doesn't do any
    # sending of audio data to Discord itself – that has to be done by
    # VoiceClient.
    parser = Discord::DCAParser.new(file)

    # A proper DCA(1) file contains metadata, which is exposed by DCAParser.
    # This metadata may be of interest, so here is some example code that uses
    # it.
    if metadata = parser.metadata
      tool = metadata.dca.tool
      client.create_message(payload.channel_id, "DCA file was created by #{tool.name}, version #{tool.version}.")

      if info = metadata.info
        client.create_message(payload.channel_id, "Song info: #{info.title} by #{info.artist}.") if info.title && info.artist
      end
    else
      client.create_message(payload.channel_id, "DCA file metadata is invalid!")
    end

    # Set the bot as speaking (green circle). This is important and has to be
    # done at least once in every voice connection, otherwise the Discord client
    # will not know who the packets we're sending belongs to.
    voice_client.not_nil!.send_speaking(true)

    client.create_message(payload.channel_id, "Playing DCA file `#{filename}`.")

    # For smooth audio streams Discord requires one packet every
    # 20 milliseconds. The `every` method measures the time it takes to run the
    # block and then sleeps 20 milliseconds minus that time before moving on to
    # the next iteration, ensuring accurate timing.
    #
    # When simply reading from DCA, the time it takes to read, process and
    # send the frame is small enough that `every` doesn't make much of a
    # difference (in fact, some users report that it actually makes things
    # worse). If the processing time is not negligibly slow because you're
    # doing something else than DCA parsing, or because you're reading from a
    # slow source, or for any other reason, then it is recommended to use
    # `every`. Otherwise, simply using a loop and `sleep`ing `20.milliseconds`
    # each time may suffice.
    Discord.every(20.milliseconds) do
      frame = parser.next_frame(reuse_buffer: true)
      break unless frame

      # Perform the actual sending of the frame to Discord.
      voice_client.not_nil!.play_opus(frame)
    end

    # Alternatively, the above code can be realised as the following:
    #
    # parser.parse do |frame|
    #   Discord.timed_run(20.milliseconds) do
    #     voice_client.not_nil!.play_opus(frame)
    #   end
    # end
    #
    # (The `parse` method reads the frames consecutively and passes them to the
    # block.)

    file.close
  end
end

# The VOICE_SERVER_UPDATE dispatch is sent by Discord once the op4 packet sent
# by voice_state_update has been processed. It tells the client the endpoint
# to connect to.
client.on_voice_server_update do |payload|
  begin
    vc = voice_client = Discord::VoiceClient.new(payload, client.session.not_nil!, current_user_id.not_nil!)
    vc.on_ready do
      client.create_message(connect_channel_id.not_nil!, "Voice connected.")
    end
    vc.run
  rescue e
    e.inspect_with_backtrace(STDOUT)
  end
end

client.run
