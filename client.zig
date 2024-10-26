const std = @import("std");

pub fn main() !void {
    const server_address = try std.net.Address.parseIp4("127.0.0.1", 8999);

    const stream = try std.net.tcpConnectToAddress(server_address);
    defer stream.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var inputThread = try std.Thread.spawn(.{}, handleInputThread, .{ stream, allocator });
    var outputThread = try std.Thread.spawn(.{}, handleOutputThread, .{ stream, allocator });

    inputThread.join();
    outputThread.join();
}

fn handleInputThread(stream: std.net.Stream, _: std.mem.Allocator) !void {
    const stdin = std.io.getStdIn();

    var stdin_buffer: [1024]u8 = undefined;

    while (true) {
        const input = try stdin.reader().readUntilDelimiterOrEof(&stdin_buffer, '\n');

        if (input) |m| {
            if (std.mem.eql(u8, m, "quit")) {
                break;
            }

            var writer = stream.writer();
            _ = try writer.write(m);
        }
    }
}

fn handleOutputThread(stream: std.net.Stream, _: std.mem.Allocator) !void {
    var stream_buffer: [1024]u8 = undefined;

    while (true) {
        const read_bytes = try stream.reader().read(&stream_buffer);

        if (read_bytes != 0) {
            const server_message = stream_buffer[0..read_bytes];
            std.debug.print("{s}\n", .{server_message});
        } else {
            std.debug.print("Lost connection to the server", .{});
            break;
        }
    }
}
