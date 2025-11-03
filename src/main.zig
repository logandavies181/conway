const std = @import("std");
const config = @import("config");
const rl = @import("raylib");

const screenWidth = 1620;
const screenHeight = 900;
const sqsize = 30;

const numBerries = 10;

const horizsqs = screenWidth/sqsize + 4;
const vertsqs = screenHeight/sqsize + 4;

var squares: [horizsqs][vertsqs]Square = undefined;

pub fn main() anyerror!void {
    if (config.disableLog) {
        rl.setTraceLogLevel(.none);
    }

    rl.initWindow(screenWidth, screenHeight + 30, "Conway's Game of Life");
    defer rl.closeWindow();

    reset();

    rl.setTargetFPS(60);

    var framesSinceConway: usize = 0;
    var conway = false;

    // Main game loop
    while (!rl.windowShouldClose()) {
        if (rl.isMouseButtonPressed(.left)) {
            const pos = rl.getMousePosition();
            const xidx, const yidx = vecToIndices(pos);
            if (yidx < vertsqs - 2) {
                squares[xidx][yidx].convert();
            } else {
                if (pos.x > screenWidth/2) {
                    conway = false;
                    reset();
                } else {
                    conway = !conway;
                }
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        if (framesSinceConway >= 30 and conway) {
            framesSinceConway = 0;

            var neighbourCounts: [horizsqs][vertsqs]u8 = undefined;
            for (0..horizsqs) |i| {
                for (0..vertsqs) |j| {
                    neighbourCounts[i][j] = getNeighbourCount(@intCast(i), @intCast(j));
                }
            }

            for (0..horizsqs) |i| {
                for (0..vertsqs) |j| {
                    const nc = neighbourCounts[i][j];
                    switch (nc) {
                        0, 1 => squares[i][j].alive = false,
                        2 => {},
                        3 => {
                            squares[i][j].setAlive();
                        },
                        else => squares[i][j].alive = false,
                    }
                }
            }
        }

        // Draw
        // Start / pause button
        rl.drawRectangle(0, sqsize*(vertsqs - 4), screenWidth/2, sqsize, if (conway) .green else .light_gray);
        rl.drawText("Start / Pause", 10, sqsize*(vertsqs - 4) + 5, 20, .black);
        // Reset button
        rl.drawRectangle(screenWidth/2, sqsize*(vertsqs - 4), screenWidth, sqsize, .light_gray);
        rl.drawText("Reset", screenWidth/2 + 10, sqsize*(vertsqs - 4) + 5, 20, .black);

        for (2..horizsqs - 2) |i| {
            for (2..vertsqs - 2) |j| {
                rl.drawRectangle(@intCast((i-2)*sqsize), @intCast((j-2)*sqsize), sqsize, sqsize, squares[i][j].colour());
            }
        }

        // Horizontal Lines
        for (0..screenHeight/sqsize+1) |_i| {
            const i: i32 = @intCast(_i);
            rl.drawLine(0, i*sqsize, screenWidth, i*sqsize, .light_gray);
        }
        // Vertical
        for (0..screenWidth/sqsize+1) |_i| {
            const i: i32 = @intCast(_i);
            rl.drawLine(i*sqsize, 0, i*sqsize, screenHeight, .light_gray);
        }
        framesSinceConway += 1;
    }
}

const SqsState = enum {
    empty,
    berry,
    seen,
};

const Square = struct {
    alive: bool,
    state: SqsState,

    fn setAlive(self: *Square) void {
        self.alive = true;
        self.state = .seen;
    }

    fn convert(self: *Square) void {
        self.alive = !self.alive;
        if (self.alive) {
            self.state = .seen;
        }
    }

    fn colour(self: *Square) rl.Color {
        if (self.alive) {
            return .black;
        }

        return switch (self.state) {
            .empty => .white,
            .berry => .red,
            .seen => .blue,
        };
    }
};

fn vecToIndices(vec: rl.Vector2) struct { usize, usize } {
    const xpos: usize = @intFromFloat(vec.x);
    const ypos: usize = @intFromFloat(vec.y);
    return .{ xpos/sqsize + 2, ypos/sqsize + 2 };
}

fn getNeighbourCount(i: i32, j: i32) u8 {
    var count: u8 = 0;
    if (isSquareAlive(i-1, j)) count += 1;
    if (isSquareAlive(i-1, j-1)) count += 1;
    if (isSquareAlive(i, j-1)) count += 1;
    if (isSquareAlive(i+1, j)) count += 1;
    if (isSquareAlive(i+1, j+1)) count += 1;
    if (isSquareAlive(i, j+1)) count += 1;
    if (isSquareAlive(i-1, j+1)) count += 1;
    if (isSquareAlive(i+1, j-1)) count += 1;
    return count;
}

fn isSquareAlive(i: i32, j: i32) bool {
    if (i < 0 or j < 0 or i >= horizsqs or j >= vertsqs) {
        return false;
    }
    return squares[@intCast(i)][@intCast(j)].alive;
}

fn reset() void {
    var berries = [_]bool{false}**((horizsqs-4)*(vertsqs-4));
    for (0..numBerries) |i| {
        berries[i] = true;
    }
    std.crypto.random.shuffle(bool, &berries);

    var idx: u64 = 0;
    for (0..horizsqs) |i| {
        for (0..vertsqs) |j| {
            squares[i][j] = .{
                .alive = false,
                .state = blk: {
                    if (berries[idx]) {
                        break :blk .berry;
                    } else {
                        break :blk .empty;
                    }
                },
            };
            if (i > 1 and i < horizsqs-2 and j > 1 and j < vertsqs-2 and idx < berries.len-1) {
                idx += 1;
            }
        }
    }
}
