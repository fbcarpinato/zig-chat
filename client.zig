const std = @import("std");

pub fn main() !void {
    const server_address = try std.net.Address.parseIp4("127.0.0.1", 8999);

    const stream = try std.net.tcpConnectToAddress(server_address);
    defer stream.close();

    const stdin = std.io.getStdIn();
    const reader = stdin.reader();

    var buffer: [1024]u8 = undefined;

    while (true) {
        const message = try reader.readUntilDelimiterOrEof(&buffer, '\n');

        if (message) |m| {
            std.debug.print("message {s}\n", .{m});

            var writer = stream.writer();
            _ = try writer.write(m);

            std.debug.print("Message {s} sent to the server\n", .{m});
        }
    }
}
