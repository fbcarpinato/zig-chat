const std = @import("std");

pub fn main() !void {
    const server_address = try std.net.Address.parseIp4("127.0.0.1", 8999);

    const stream = try std.net.tcpConnectToAddress(server_address);
    defer stream.close();

    const stdin = std.io.getStdIn();

    var stdin_buffer: [1024]u8 = undefined;
    var stream_buffer: [1024]u8 = undefined;

    while (true) {
        const input = try stdin.reader().readUntilDelimiterOrEof(&stdin_buffer, '\n');

        if (input) |m| {
            std.debug.print("message {s}\n", .{m});

            var writer = stream.writer();
            _ = try writer.write(m);

            std.debug.print("Message {s} sent to the server\n", .{m});
        }

        std.debug.print("Trying to read some bytes from the server\n", .{});

        const read_bytes = try stream.reader().read(&stream_buffer);

        std.debug.print("Read {} bytes from server\n", .{read_bytes});

        if (read_bytes > 0) {
            const server_message = stream_buffer[0..read_bytes];
            std.debug.print("Received message from server: {s}\n", .{server_message});
        }
    }
}
