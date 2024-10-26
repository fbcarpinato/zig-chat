const std = @import("std");

pub fn main() !void {
    const server_address = try std.net.Address.parseIp4("127.0.0.1", 8999);

    const stream = try std.net.tcpConnectToAddress(server_address);
    defer stream.close();

    var inputThread = try std.Thread.spawn(.{}, handleInputThread, .{stream});
    var outputThread = try std.Thread.spawn(.{}, handleOutputThread, .{stream});

    inputThread.join();
    outputThread.join();
}

fn handleInputThread(stream: std.net.Stream) !void {
    const stdin = std.io.getStdIn();

    var stdin_buffer: [1024]u8 = undefined;

    while (true) {
        const input = try stdin.reader().readUntilDelimiterOrEof(&stdin_buffer, '\n');

        if (input) |m| {
            std.debug.print("message {s}\n", .{m});

            var writer = stream.writer();
            _ = try writer.write(m);

            std.debug.print("Message {s} sent to the server\n", .{m});
        }
    }
}

fn handleOutputThread(stream: std.net.Stream) !void {
    var stream_buffer: [1024]u8 = undefined;

    while (true) {
        const read_bytes = try stream.reader().read(&stream_buffer);

        std.debug.print("Read {} bytes from server\n", .{read_bytes});

        if (read_bytes > 0) {
            const server_message = stream_buffer[0..read_bytes];
            std.debug.print("Received message from server: {s}\n", .{server_message});
        }
    }
}
