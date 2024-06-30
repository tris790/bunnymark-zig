const std = @import("std");
const c = @cImport(@cInclude("raylib.h"));

const MAX_BUNNIES = 500000;
const MAX_BATCH_ELEMENTS = 8192;

const Bunny = struct {
    position: c.Vector2,
    speed: c.Vector2,
    color: c.Color,
};

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 450;

    c.InitWindow(screenWidth, screenHeight, "raylib [textures] example - bunnymark");

    const texBunny: c.Texture2D = c.LoadTexture("/home/fbi/repo/zig/bunnymark-zig/src/resources/wabbit_alpha.png");
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var bunnies: []Bunny = try allocator.alloc(Bunny, MAX_BUNNIES);

    var bunniesCount: u32 = 0; // Bunnies counter

    c.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    while (!c.WindowShouldClose()) // Detect window close button or ESC key
    {
        if (c.IsMouseButtonDown(c.MOUSE_BUTTON_LEFT)) {
            for (0..100) |_| {
                if (bunniesCount < MAX_BUNNIES) {
                    bunnies[bunniesCount].position = c.GetMousePosition();
                    bunnies[bunniesCount].speed.x = @as(f32, @floatFromInt(c.GetRandomValue(-250, 250))) / 60.0;
                    bunnies[bunniesCount].speed.y = @as(f32, @floatFromInt(c.GetRandomValue(-250, 250))) / 60.0;
                    bunnies[bunniesCount].color = c.Color{ .r = @intCast(c.GetRandomValue(50, 240)), .g = @intCast(c.GetRandomValue(80, 240)), .b = @intCast(c.GetRandomValue(100, 240)), .a = 255 };
                    bunniesCount += 1;
                }
            }
        }

        for (0..bunniesCount) |i| {
            bunnies[i].position.x += bunnies[i].speed.x;
            bunnies[i].position.y += bunnies[i].speed.y;
            const half_width: f32 = @as(f32, @floatFromInt(texBunny.width)) / 2.0;
            const half_height: f32 = @as(f32, @floatFromInt(texBunny.height)) / 2.0;
            const pos_x = bunnies[i].position.x + half_width;
            const pos_y = bunnies[i].position.y + half_height;
            const screen_size_x = @as(f32, @floatFromInt(c.GetScreenWidth()));
            const screen_size_y = @as(f32, @floatFromInt(c.GetScreenHeight()));
            if (pos_x > screen_size_x or pos_x < 0) {
                bunnies[i].speed.x *= -1;
            }
            if (pos_y > screen_size_y or pos_y - 40 < 0) {
                bunnies[i].speed.y *= -1;
            }
        }
        
        // Draw
        //----------------------------------------------------------------------------------
        c.BeginDrawing();
        {
            c.ClearBackground(c.RAYWHITE);

            for (0..bunniesCount) |i| {
                // NOTE: When internal batch buffer limit is reached (MAX_BATCH_ELEMENTS),
                // a draw call is launched and buffer starts being filled again;
                // before issuing a draw call, updated vertex data from internal CPU buffer is send to GPU...
                // Process of sending data is costly and it could happen that GPU data has not been completely
                // processed for drawing while new data is tried to be sent (updating current in-use buffers)
                // it could generates a stall and consequently a frame drop, limiting the number of drawn bunnies
                c.DrawTexture(texBunny, @intFromFloat(bunnies[i].position.x), @intFromFloat(bunnies[i].position.y), bunnies[i].color);
            }

            c.DrawRectangle(0, 0, screenWidth, 40, c.BLACK);
            c.DrawText(c.TextFormat("bunnies: %i", bunniesCount), 120, 10, 20, c.GREEN);
            c.DrawText(c.TextFormat("batched draw calls: %i", 1 + bunniesCount / MAX_BATCH_ELEMENTS), 320, 10, 20, c.MAROON);

            c.DrawFPS(10, 10);
        }
        c.EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------

    c.UnloadTexture(texBunny); // Unload bunny texture

    c.CloseWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}
