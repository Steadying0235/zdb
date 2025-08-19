const std = @import("std");
const clap = @import("clap");
const c = @cImport({
    @cInclude("sys/ptrace.h");
    @cInclude("sys/types.h");
});

pub fn attach(argc: c_int, argv: **c_char) c.pid_t {
    _ = argc;
    _ = argv;
    unreachable;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-p, --pid <usize>   pid of the process to attach to
        \\
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        // Report useful error and exit.
        try diag.report(std.io.getStdErr().writer(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        try clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    if (res.args.pid) |p|
        std.debug.print("--pid = {}\n", .{p});
}
