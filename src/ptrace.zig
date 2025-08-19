const std = @import("std");
const c = @cImport({
    @cInclude("sys/ptrace.h");
});

pub fn main() !void {
    const pid: c.pid_t = 1234;
    _ = c.ptrace(c.PTRACE_ATTACH, pid, 0, 0);
}
