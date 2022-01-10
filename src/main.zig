const c = @cImport({
    @cInclude("glad.h");
    @cInclude("X11/Xlib.h");
    @cInclude("GL/gl.h");
    @cInclude("GL/glx.h");
    @cInclude("GL/glxext.h");
});

const std = @import("std");
const maths = @import("maths.zig");

pub fn main() !void {

    // Connect to X display
    var display = c.XOpenDisplay(null);
    if (display == null) {
        std.debug.print("XOpenDisplay returned null\n", .{});
        return;
    }

    // Create a rendering window
    var rootWindow = c.XDefaultRootWindow(display);
    var window = c.XCreateSimpleWindow(display, rootWindow, 0, 0, 800, 600, 0, 0, 0);

    // Set a window title
    _ = c.XStoreName(display, window, "Hello world");

    // Map it so we can see it
    _ = c.XMapWindow(display, window);

    // We want to be informed about the window close event.
    var wmDelete = c.XInternAtom(display, "WM_DELETE_WINDOW", c.True);
    _ = c.XSetWMProtocols(display, window, &wmDelete, 1);

    // Choose the most suitable framebuffer format
    const attribList = [_]i32 {
        c.GLX_DOUBLEBUFFER, c.True,
        c.GLX_DEPTH_SIZE, 24,
        c.None
    };
    var numElements: i32 = undefined;
    const fbo = c.glXChooseFBConfig(display, 0, &attribList, &numElements);

    // Create a context using that framebuffer format
    const contextAttribs = [_]i32 {
        c.GLX_CONTEXT_MAJOR_VERSION_ARB, 4,
        c.GLX_CONTEXT_MINOR_VERSION_ARB, 6,
        c.None
    };

    var glXCreateContextAttribsARB = @ptrCast(c.PFNGLXCREATECONTEXTATTRIBSARBPROC, c.glXGetProcAddress("glXCreateContextAttribsARB")).?;
    var context = glXCreateContextAttribsARB(display, fbo[0], null, c.True, &contextAttribs);
    _ = c.glXMakeCurrent(display, window, context);
    _ = c.gladLoadGL();

    // Set up some opengl global settings
    c.glClearColor(0.2, 0.4, 0.6, 1.0);
    c.glClearDepth(1.0);
    c.glEnable(c.GL_DEPTH_TEST);

    // Load the things we need to draw
     const mesh = loadMesh();
     const program = loadShader();

    var angle: f32 = 0.0;

    // Run an event loop so we can interact with it
    var done = false;
    while(!done) {
        while(c.XPending(display) > 0) {
            var event: c.XEvent = undefined;
            _ = c.XNextEvent(display, &event);

            if (event.type == c.ClientMessage and event.xclient.data.l[0] == wmDelete) {
                done = true;
            }
        }

        var transform = maths.rotateZ(angle);
        angle  = angle + 0.01;

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        c.glUseProgram(program);
        c.glUniformMatrix4fv(0, 1, c.GL_FALSE, maths.mat4_ptr(&transform));
        c.glBindVertexArray(mesh.vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, mesh.numElements);

        c.glXSwapBuffers(display, window);
    }
}

const Mesh = struct {
    vao: c.GLuint,
    numElements: c.GLint
};

fn loadMesh() Mesh {
    var vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);

    var vbo: c.GLuint = undefined;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, triangle.len * @sizeOf(f32), &triangle, c.GL_STATIC_DRAW);
    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 0, @intToPtr(?*i32, 0));

    return .{.vao = vao, .numElements = 3};
}

fn loadShader() c.GLuint {

    var vert_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vert_shader, 1, &vert_shader_text, null);
    c.glCompileShader(vert_shader);

    var frag_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(frag_shader, 1, &frag_shader_text, null);
    c.glCompileShader(frag_shader);

    var program = c.glCreateProgram();
    c.glAttachShader(program, vert_shader);
    c.glAttachShader(program, frag_shader);
    c.glLinkProgram(program);

    return program;
}


//
// The data we need for the demo
//

const triangle = [_]f32 {
    -0.866, -0.5,0.0,
    0.866, -0.5, 0.0,
    0.0, 1.0, 0.0,
};

const vert_shader_text: [*:0]const u8 =
    \\ #version 460
    \\
    \\ layout(location=0) uniform mat4 transform;
    \\ layout(location=0) in vec3 position_in;
    \\
    \\ void main()
    \\ {
    \\     gl_Position = transform * vec4(position_in, 1.0);   
    \\ }
;

const frag_shader_text:[*:0]const u8 =
    \\ #version 460
    \\
    \\ out vec4 colour_out;
    \\
    \\ void main()
    \\ {
    \\     colour_out = vec4(1.0, 0.0, 0.0, 1.0);   
    \\ }
;

