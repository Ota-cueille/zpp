const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const compiler = b.addExecutable(.{
        .name = "langc",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(compiler);

    const tests = b.step("test", "Run Unit Tests");

    const build_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests_artifact = b.addRunArtifact(build_tests);
    tests.dependOn(&tests_artifact.step);
}
