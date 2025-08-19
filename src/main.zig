const std = @import("std");
const clap = @import("clap");
const c = @cImport({
    @cInclude("sys/ptrace.h");
    @cInclude("editline/readline.h");
});
const linux = std.os.linux;
const Pid = linux.pid_t;

const cNullPtr: ?*anyopaque = null;

const PTRACE_ATTACH = 16;
const PTRACE_DETACH = 17;

pub fn attach(pid: Pid) void {
    const res = c.ptrace(PTRACE_ATTACH, pid, cNullPtr, cNullPtr);
    if (res == -1) {
        // ptraceError
        std.debug.print("failed to attach to process: {}\n", .{pid});
        return;
    }
    std.debug.print("successfully attached to process: {}\n", .{pid});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-p, --pid <i32>   pid of the process to attach to
        \\
    );
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
    if (res.args.pid) |p| {
        std.debug.print("--pid = {}\n", .{p});
        attach(p);
        _ = c.ptrace(PTRACE_DETACH, p, cNullPtr, cNullPtr);
    }
}
