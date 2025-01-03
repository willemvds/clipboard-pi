const std = @import("std");
const sdl3 = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const HandleClipboardEventResult = struct {
    textures: std.ArrayList(*sdl3.SDL_Texture),
};

pub fn handleClipboardEvent(
    a: std.mem.Allocator,
    ev: sdl3.SDL_ClipboardEvent,
    renderer: *sdl3.SDL_Renderer,
    font: *sdl3.TTF_Font,
) !HandleClipboardEventResult {
    std.debug.print("clipboard event = {}\n", .{ev});

    const numMimeTypes: usize = @intCast(ev.n_mime_types);
    const green = sdl3.SDL_Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
    var textures = try std.ArrayList(*sdl3.SDL_Texture).initCapacity(a, numMimeTypes);

    for (0..numMimeTypes) |idx| {
        std.debug.print("mime type #{d} = {s}\n", .{ idx, ev.mime_types[idx] });
        const mimeLabelTexture = try createTextTexture(renderer, font, green, std.mem.span(ev.mime_types[idx]));
        try textures.append(mimeLabelTexture);
    }

    return HandleClipboardEventResult{
        .textures = textures,
    };
}

pub fn createTextTexture(
    renderer: *sdl3.SDL_Renderer,
    font: *sdl3.TTF_Font,
    colour: sdl3.SDL_Color,
    msg: []const u8,
) !*sdl3.SDL_Texture {
    const textSurface = sdl3.TTF_RenderText_Blended(font, @ptrCast(msg), msg.len, colour);
    const textTex = sdl3.SDL_CreateTextureFromSurface(renderer, textSurface);
    sdl3.SDL_DestroySurface(textSurface);
    return textTex;
}

const CreateWindowAndRendererResult = struct {
    window: *sdl3.SDL_Window,
    renderer: *sdl3.SDL_Renderer,
};

pub fn createWindowAndRenderer(window_width: c_int, window_height: c_int, window_title: []const u8, window_flags: u64) !CreateWindowAndRendererResult {
    var maybeWindow: ?*sdl3.SDL_Window = undefined;
    var maybeRenderer: ?*sdl3.SDL_Renderer = undefined;

    if (!sdl3.SDL_CreateWindowAndRenderer(
        @ptrCast(window_title),
        window_width,
        window_height,
        window_flags,
        &maybeWindow,
        &maybeRenderer,
    )) {
        return error.SDL;
    }

    if (maybeWindow) |window| {
        if (maybeRenderer) |renderer| {
            return CreateWindowAndRendererResult{
                .window = window,
                .renderer = renderer,
            };
        }
    }

    unreachable();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Clipboard PI\n", .{});
    try bw.flush(); // don't forget to flush!

    if (sdl3.SDL_Init(sdl3.SDL_INIT_VIDEO) == false) {
        std.debug.print("SDL init err = {s}\n", .{sdl3.SDL_GetError()});
        return;
    }

    const primaryDisplayId = sdl3.SDL_GetPrimaryDisplay();
    if (primaryDisplayId == 0) {
        return error.SDL;
    }
    const desktopDisplayMode = sdl3.SDL_GetDesktopDisplayMode(primaryDisplayId) orelse {
        return error.SDL;
    };

    std.debug.print("primary display mode: id={d} pixel_format={} w={d} h={d} pixel_density={d} refresh_rate={d}\n", .{
        desktopDisplayMode.*.displayID,
        desktopDisplayMode.*.format,
        desktopDisplayMode.*.w,
        desktopDisplayMode.*.h,
        desktopDisplayMode.*.pixel_density,
        desktopDisplayMode.*.refresh_rate,
    });

    const window_w: c_int = desktopDisplayMode.*.w - 300;
    const window_h: c_int = desktopDisplayMode.*.h - 300;
    const window_title = "Clipboard PI";
    const window_flags =
        //        sdl3.SDL_WINDOW_BORDERLESS |
        sdl3.SDL_WINDOW_TRANSPARENT |
        sdl3.SDL_WINDOW_INPUT_FOCUS |
        sdl3.SDL_WINDOW_RESIZABLE;

    const createWindowAndRendererResult = try createWindowAndRenderer(window_w, window_h, window_title, window_flags);
    //    const window = createWindowAndRendererResult.window;
    const renderer = createWindowAndRendererResult.renderer;

    if (sdl3.TTF_Init() == false) {
        std.debug.print("SDL_ttf init err = {s}\n", .{sdl3.SDL_GetError()});
        return error.SDL;
    }

    //    const SDL_CLOSE_IO = true;
    const uiFont = sdl3.TTF_OpenFont("/home/willem/Downloads/SourceCodePro/SauceCodeProNerdFont-Regular.ttf", 24) orelse {
        std.debug.print("font loading err = {s}\n", .{sdl3.SDL_GetError()});
        return error.SDL;
    };

    const green = sdl3.SDL_Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
    const msg = "Clipboard Private Investigator \u{f408}  ";
    const msgTex = try createTextTexture(renderer, uiFont, green, msg);

    var labelTextures = try std.ArrayList(*sdl3.SDL_Texture).initCapacity(ally, 0);

    _ = sdl3.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl3.SDL_ALPHA_TRANSPARENT);
    _ = sdl3.SDL_SetRenderDrawBlendMode(renderer, sdl3.SDL_BLENDMODE_BLEND);

    var quit = false;
    while (!quit) {
        _ = sdl3.SDL_RenderClear(renderer);
        const targetRect = sdl3.SDL_FRect{ .w = @floatFromInt(msgTex.w), .h = @floatFromInt(msgTex.h) };
        _ = sdl3.SDL_RenderTexture(renderer, msgTex, null, &targetRect);

        for (labelTextures.items, 0..) |labelTexture, idx| {
            const y: f32 = @floatFromInt(idx * @as(usize, @intCast(labelTexture.h)));
            const tr = sdl3.SDL_FRect{
                .x = 10.0,
                .y = 100.0 + y,
                .w = @floatFromInt(labelTexture.w),
                .h = @floatFromInt(labelTexture.h),
            };
            _ = sdl3.SDL_RenderTexture(renderer, labelTexture, null, &tr);
        }

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
                    const cbResult = try handleClipboardEvent(ally, cbev, renderer, uiFont);
                    labelTextures = cbResult.textures;
                },
                else => {},
            }
        }
    }
}
