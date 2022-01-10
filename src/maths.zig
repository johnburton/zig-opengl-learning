const std = @import("std");
const math = std.math;

const Mat4 = struct {
    v: [4][4]f32 = undefined
};

pub fn identity() Mat4 {
    return .{.v = .{
        [_]f32 {1.0, 0.0, 0.0, 0.0},
        [_]f32 {0.0, 1.0, 0.0, 0.0},
        [_]f32 {0.0, 0.0, 1.0, 0.0},
        [_]f32 {0.0, 0.0, 0.0, 1.0}
    }};
}


pub fn rotateZ(angle: f32) Mat4 {
    return .{.v = .{
        [_]f32 {math.cos(angle), math.sin(angle),  0.0, 0.0},
        [_]f32 {-math.sin(angle), math.cos(angle), 0.0, 0.0},
        [_]f32 {0.0, 0.0, 1.0, 0.0},
        [_]f32 {0.0, 0.0, 0.0, 1.0}
    }};
}

pub fn mat4_ptr(mat: *Mat4) *f32 {
    return &mat.v[0][0];
}