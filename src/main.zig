const std = @import("std");
const net = std.net;

const stdout = std.io.getStdOut().writer();

const prompt = "fairywren> ";

const cmdPing = "PING";
const cmdSet = "SET";
const cmdGet = "GET";

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const addr = try net.Address.parseIp4("127.0.0.1", 1111);

    var srv = std.net.StreamServer.init(.{});
    defer srv.deinit();
    try srv.listen(addr);

    var db = std.StringHashMap([]u8).init(allocator);

    while (true) {
        const conn = try srv.accept();
        handle(conn, db) catch |err| {
            try stdout.print("connection dropped {}: {}\n", .{ conn.address, err });
        };
    }
}

fn handle(conn: net.StreamServer.Connection, db: std.StringHashMap([]u8)) !void {
    while (true) {
        try conn.stream.writeAll(prompt);
        var buf: [1024]u8 = undefined;
        const amt = try conn.stream.read(&buf);
        const msg = std.mem.trim(u8, buf[0..amt], "\n ");

        if (std.mem.eql(u8, msg, cmdPing)) {
            try conn.stream.writeAll("PONG\n");
            continue;
        }

        const iter = std.mem.splitScalar(u8, msg, ' ');

        if (std.mem.startsWith(u8, msg, cmdSet)) {
            try db.put(iter.next(), iter.next());
            continue;
        }

        if (std.mem.startsWith(u8, msg, cmdGet)) {
            continue;
        }

        try conn.stream.writeAll("unknown command\n");
    }
}
