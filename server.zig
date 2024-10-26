const std = @import("std");

pub fn main() !void {
    const loopback = try std.net.Ip4Address.parse("127.0.0.1", 8999);
    const address = std.net.Address{ .in = loopback };

    var server = try address.listen(.{});
    defer server.deinit();

    std.debug.print("Server listening at port: {}\n", .{address.getPort()});

    while (true) {
        const client = try server.accept();

        var thread = try std.Thread.spawn(.{}, handleClient, .{client});

        thread.detach();
    }
}

fn handleClient(client: std.net.Server.Connection) void {
    defer client.stream.close();

    std.debug.print("Connection received from {}\n", .{client.address});

    const buffer_size = 1024;
    var buffer: [buffer_size]u8 = undefined;

    while (true) {
        const read_bytes = client.stream.reader().read(&buffer) catch |err| {
            std.debug.print("Error reading message: {}\n", .{err});
            break;
        };

        if (read_bytes > 0) {
            const message = buffer[0..read_bytes];
            std.debug.print("Received message from {}: {s}\n", .{ client.address, message });

            _ = client.stream.writer().write("Your message has been received from the server") catch |err| {
                std.debug.print("Error writing a response for the client {}\n", .{err});
                break;
            };
        }
    }
}
