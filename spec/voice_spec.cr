require "./spec_helper"

private def with_voice_udp
  server = UDPSocket.new
  server.bind("localhost", 0)
  port = server.local_address.port
  client = Discord::VoiceUDP.new
  client.connect("localhost", port.to_u32, 1_u32)
  yield server, client
  server.close
  client.socket.close
end

describe Discord::VoiceUDP do
  it "sends discovery" do
    with_voice_udp do |server, client|
      client.send_discovery
      data = Bytes.new(70)
      server.receive(data)
      data[0, 4].should eq Bytes[0, 0, 0, 1]
    end
  end

  it "receives discovery reply" do
    with_voice_udp do |server, client|
      io = IO::Memory.new
      io.write Bytes.new(4)
      io.print("ip address".ljust(64, '\0'))
      io.write_bytes(2_u16, IO::ByteFormat::BigEndian)
      data = io.to_slice
      server.send(data, to: client.socket.local_address)

      ip, port = client.receive_discovery_reply
      ip.should eq "ip address"
      port.should eq 2_u16
    end
  end

  it "creates voice header" do
    with_voice_udp do |server, client|
      data = client.create_header(1_u16, 2_u32)
      data[0, 2].should eq Bytes[0x80, 0x78]
      data[2, 2].should eq Bytes[0, 1]
      data[4, 4].should eq Bytes[0, 0, 0, 2]
      data[8, 4].should eq Bytes[0, 0, 0, 1]
    end
  end
end
