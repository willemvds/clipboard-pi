const std = @import("std");
const sdl3 = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

pub fn handleClipboardEvent(ev: sdl3.SDL_ClipboardEvent) void {
    std.debug.print("clipboard event = {}\n", .{ev});
    for (0..@intCast(ev.n_mime_types)) |idx| {
        std.debug.print("mime type #{d} = {s}\n", .{ idx, ev.mime_types[idx] });
    }
}

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

    if (sdl3.TTF_Init() == false) {
        std.debug.print("SDL_ttf init err = {s}\n", .{sdl3.SDL_GetError()});
        return error.SDL;
    }

    //    const SDL_CLOSE_IO = true;
    const uiFont = sdl3.TTF_OpenFont("/home/willem/Downloads/SourceCodePro/SauceCodeProNerdFont-Regular.ttf", 24);
    if (uiFont == null) {
        std.debug.print("font loading err = {s}\n", .{sdl3.SDL_GetError()});
        return error.SDL;
    }

    const tempText = sdl3.SDL_CreateSurface(600, 200, sdl3.SDL_PIXELFORMAT_RGBA32);
    if (tempText == null) {
        std.debug.print("create surface err = {s}\n", .{sdl3.SDL_GetError()});
        return error.SDL;
    }

    const green = sdl3.SDL_Color{ .r = 0, .g = 255, .b = 0, .a = 255 };

    var quit = false;
    while (!quit) {
        _ = sdl3.SDL_RenderClear(renderer);
        const msg = "Clipboard Private Investigator \u{f408}  ";
        const textSurface = sdl3.TTF_RenderText_Blended(uiFont, msg, msg.len, green);
        const textTex = sdl3.SDL_CreateTextureFromSurface(renderer, textSurface);
        sdl3.SDL_DestroySurface(textSurface);
        const targetRect = sdl3.SDL_FRect{ .w = 1200.0, .h = 100.0 };
        _ = sdl3.SDL_RenderTexture(renderer, textTex, null, &targetRect);
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
                sdl3.SDL_EVENT_CLIPBOARD_UPDATE => {
                    const cbev: sdl3.SDL_ClipboardEvent = e.clipboard;
                    handleClipboardEvent(cbev);
                },
                else => {},
            }
        }
    }
}
