const std = @import("std");
const clap = @import("clap");
const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("sys/ptrace.h");
    @cInclude("editline/readline.h");
});
const linux = std.os.linux;
const Pid = linux.pid_t;

const cNullPtr: ?*anyopaque = null;

const PTRACE_TRACEME = 0;

const PTRACE_ATTACH = 16;
const PTRACE_DETACH = 17;

const PtraceError = error{
    AttachError,
    ForkError,
    TraceError,
    ExecutionError,
};

// TODO: Setup proper error handling
// // returns pid of child process or error
pub fn attach(pid: Pid) !Pid {
    const res = c.ptrace(PTRACE_ATTACH, pid, cNullPtr, cNullPtr);
    if (res == -1) {
        std.debug.print("failed to attach to process: {}\n", .{pid});
        return PtraceError.AttachError;
    }
    std.debug.print("successfully attached to process: {}\n", .{pid});
    const program_path: []const u8 = undefined;

    pid = linux.fork();
    if (pid < 0) {
        // error during fork
        return PtraceError.ForkError;
    } else if (pid == 0) {
        if (c.ptrace(PTRACE_TRACEME, 0, cNullPtr, cNullPtr) == -1) {
            // error trying to trace child
            return PtraceError.TraceError;
        }
        if (c.execlp(program_path, program_path, cNullPtr) == -1) {
            // error executing process
            return PtraceError.ExecutionError;
        }
    }
    return pid;
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

    if (linux.waitpid(_, &wait_status, 0) == -1) {
        // waitpid failed
    }
}
