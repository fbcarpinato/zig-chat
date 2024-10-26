const std = @import("std");

pub fn main() !void {
    const loopback = try std.net.Ip4Address.parse("127.0.0.1", 8999);
    const address = std.net.Address{ .in = loopback };

    var server = try address.listen(.{});
    defer server.deinit();

    std.debug.print("Server listening at port: {}\n", .{address.getPort()});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var connected_clients = std.AutoHashMap(u32, std.net.Server.Connection).init(allocator);
    defer connected_clients.deinit();

    var next_client_idx: u32 = 0;

    while (true) {
        const client = try server.accept();

        try connected_clients.put(next_client_idx, client);

        var thread = try std.Thread.spawn(.{}, handleClient, .{ client, next_client_idx });

        next_client_idx += 1;

        thread.detach();
    }
}

fn handleClient(client: std.net.Server.Connection, client_idx: u32) !void {
    defer client.stream.close();

    std.debug.print("Connection received from {} with index {}\n", .{ client.address, client_idx });

    _ = try client.stream.writer().print("You have been assigned the index {}", .{client_idx});

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

            _ = client.stream.writer().write("your message has been received from the server") catch |err| {
                std.debug.print("error writing a response for the client {}\n", .{err});
                break;
            };
        }
    }
}
