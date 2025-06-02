const std = @import("std");
const config = @import("config");
const rl = @import("raylib");

const screenWidth = 810;
const screenHeight = 450;
const sqsize = 30;

const horizsqs = screenWidth/sqsize + 4;
const vertsqs = screenHeight/sqsize + 4;

var squares = initializeSquares();

pub fn main() anyerror!void {
    if (config.disableLog) {
        rl.setTraceLogLevel(.none);
    }

    rl.initWindow(screenWidth, screenHeight + 30, "Conway's Game of Life");
    defer rl.closeWindow();


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
                            squares[i][j].alive = true;
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

        for (2..horizsqs - 2) |i| {
            for (2..vertsqs - 2) |j| {
                if (squares[i][j].alive) {
                    rl.drawRectangle(@intCast((i-2)*sqsize), @intCast((j-2)*sqsize), sqsize, sqsize, .black);
                }
            }
        }
        framesSinceConway += 1;
    }
}

const Square = struct {
    alive: bool,

    fn convert(self: *Square) void {
        self.alive = !self.alive;
    }
};

fn initializeSquares() [horizsqs][vertsqs]Square {
    var ret: [horizsqs][vertsqs]Square = undefined;

    for (0..horizsqs) |i| {
        for (0..vertsqs) |j| {
            ret[i][j] = .{
                .alive = false,
            };
        }
    }

    return ret;
}

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
    for (0..horizsqs) |i| {
        for (0..vertsqs) |j| {
            squares[i][j].alive = false;
        }
    }
}
