const std = @import("std");

pub fn main() !void {
    const server_address = try std.net.Address.parseIp4("127.0.0.1", 3000);

    const stream = try std.net.tcpConnectToAddress(server_address);
    defer stream.close();

    const message = "i have connected!";
    var writer = stream.writer();
    _ = try writer.write(message);

    std.debug.print("Message {s} sent to the server", .{message});
}
