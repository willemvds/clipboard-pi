const std = @import("std");
const sdl3 = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try bw.flush(); // don't forget to flush!

    try stdout.print("Clipboard PI\n", .{});

    if (sdl3.SDL_Init(sdl3.SDL_INIT_VIDEO) == false) {
        std.debug.print("SDL init err = {s}\n", .{sdl3.SDL_GetError()});
        return;
    }

    const window_w: c_int = 1920;
    const window_h: c_int = 1080;
    const window_title = "Clipboard PI";
    const window_flags =
        sdl3.SDL_WINDOW_BORDERLESS |
        sdl3.SDL_WINDOW_INPUT_FOCUS |
        sdl3.SDL_WINDOW_RESIZABLE;

    var window: ?*sdl3.SDL_Window = undefined;
    var renderer: ?*sdl3.SDL_Renderer = undefined;

    if (!sdl3.SDL_CreateWindowAndRenderer(
        window_title,
        window_w,
        window_h,
        window_flags,
        &window,
        &renderer,
    )) {
        return error.SDL;
    }

    var quit = false;
    while (!quit) {
        _ = sdl3.SDL_RenderClear(renderer);
        _ = sdl3.SDL_RenderPresent(renderer);

        var e: sdl3.SDL_Event = undefined;
        while (sdl3.SDL_PollEvent(&e)) {
            switch (e.type) {
                sdl3.SDL_EVENT_QUIT => {
                    quit = true;
                },
                sdl3.SDL_EVENT_KEY_DOWN => {
                    const kdev: sdl3.SDL_KeyboardEvent = e.key;
                    if (kdev.key == sdl3.SDLK_ESCAPE) {
                        quit = true;
                    }
                },
                else => {},
            }
        }
    }
}
