const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const loopback = try std.net.Ip4Address.parse("127.0.0.1", 3000);

    const address = std.net.Address{ .in = loopback };

    var server = try address.listen(.{});
    defer server.deinit();

    std.debug.print("Server listening at port: {}\n", .{address.getPort()});

    while (true) {
        var client = try server.accept();
        defer client.stream.close();

        std.debug.print("Connection received from {}\n", .{client.address});

        const message = try client.stream.reader().readAllAlloc(allocator, 1024);
        defer allocator.free(message);

        std.debug.print("Received message: {s}\n", .{message});
    }
}
