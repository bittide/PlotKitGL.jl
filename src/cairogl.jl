# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module CairoGL

import GLFW
using ModernGL
using Cairo


using ..PlotKitCairo: Pik, cairo_memory_surface_ctx, draw, PlotKitCairo 

export closed,checkresized,close,CairoWindow,init,interpret_key,swap,key


##############################################################################

struct Texture
    id
    data
    width
    height
    bpp
end

function Texture(pik::Pik; interp=GL_LINEAR)
    # in textures, 0,0 is at the bottom
    # in Cairo, 0,0 is at the top
    # we'll fix this using the texture coordinates
    bpp = 3
    te = jglGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, te[1])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, interp)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, interp)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, pik.width, pik.height,
                 0, GL_BGRA, GL_UNSIGNED_BYTE, pik.img)
    glBindTexture(GL_TEXTURE_2D, 0) # unbind
    return Texture(te[1], pik.img, pik.width, pik.height, bpp)
end

function bind(tex::Texture, slot=0)
    glActiveTexture(GL_TEXTURE0+slot)
    glBindTexture(GL_TEXTURE_2D, tex.id)
end

function unitbind(tex::Texture, slot=0)
  glBindTextureUnit(slot, tex.id)
end

unbind(tex::Texture) = glBindTexture(GL_TEXTURE_2D, 0)
del(tex::Texture) = glDeleteTextures(1, [tex.id])
                    


##############################################################################
# glfw


mutable struct Window
    glfw_window
    keydict
    previous_time
    width
    height
end

function Window(width, height)
    width = Int64(round(width))
    height = Int64(round(height))
    glfw_setup()
    gwindow = GLFW.CreateWindow(width, height, "Window")
    GLFW.MakeContextCurrent(gwindow)
    GLFW.SwapInterval(1)
    keydict = Dict()
    previous_time = GLFW.time()
    A = Window(gwindow, keydict, previous_time, width, height)
    return A
end

key(A::Window, k::GLFW.Key) = GLFW.GetKey(A.glfw_window, Int32(k))
closed(A::Window) = GLFW.WindowShouldClose(A.glfw_window)

function swap(A::Window)
    GLFW.SwapBuffers(A.glfw_window)
    GLFW.PollEvents()

    t = GLFW.time();
    dt = t - A.previous_time
    A.previous_time = t
    return dt
end

finish(A::Window) =  GLFW.DestroyWindow(A.glfw_window)

function glfw_setup()
    GLFW.Init()
    window_hint = [
        (GLFW.SAMPLES,      0),
        (GLFW.DEPTH_BITS,   0),
        (GLFW.ALPHA_BITS,   8),
        (GLFW.RED_BITS,     8),
        (GLFW.GREEN_BITS,   8),
        (GLFW.BLUE_BITS,    8),
        (GLFW.STENCIL_BITS, 0),
        (GLFW.AUX_BUFFERS,  0),
        (GLFW.CONTEXT_VERSION_MAJOR, 4),# minimum OpenGL v. 3
        (GLFW.CONTEXT_VERSION_MINOR, 6),# minimum OpenGL v. 3.3
        (GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE),
        #(GLFW.OPENGL_DEBUG_CONTEXT, GL_TRUE),
        #(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE),
    ]
    for (key, value) in window_hint
        GLFW.WindowHint(key, value)
    end
    fixtitle_pre_window_creation()
end

function key_is_number(key)
    numkeys = (GLFW.KEY_0,
               GLFW.KEY_1,
               GLFW.KEY_2,
               GLFW.KEY_3,
               GLFW.KEY_4,
               GLFW.KEY_5,
               GLFW.KEY_6,
               GLFW.KEY_7,
               GLFW.KEY_8,
               GLFW.KEY_9)
    i = findfirst(x -> x == key, numkeys)
    if isnothing(i)
        return false, 0 
    end
    return true, i-1
end

function interpret_key(key)
    keydict = Dict(
	GLFW.KEY_SPACE              => ' ',
	GLFW.KEY_APOSTROPHE         => Char(39),
	GLFW.KEY_COMMA              => ',',
	GLFW.KEY_MINUS              => '-',
	GLFW.KEY_PERIOD             => '.',
	GLFW.KEY_SLASH              => '/',
	GLFW.KEY_0                  => '0',
	GLFW.KEY_1                  => '1',
	GLFW.KEY_2                  => '2',
	GLFW.KEY_3                  => '3',
	GLFW.KEY_4                  => '4',
	GLFW.KEY_5                  => '5',
	GLFW.KEY_6                  => '6',
	GLFW.KEY_7                  => '7',
	GLFW.KEY_8                  => '8',
	GLFW.KEY_9                  => '9',
	GLFW.KEY_SEMICOLON          => ';',
	GLFW.KEY_EQUAL              => '=',
	GLFW.KEY_A                  => 'a',
	GLFW.KEY_B                  => 'b',
	GLFW.KEY_C                  => 'c',
	GLFW.KEY_D                  => 'd',
	GLFW.KEY_E                  => 'e',
	GLFW.KEY_F                  => 'f',
	GLFW.KEY_G                  => 'g',
	GLFW.KEY_H                  => 'h',
	GLFW.KEY_I                  => 'i',
	GLFW.KEY_J                  => 'j',
	GLFW.KEY_K                  => 'k',
	GLFW.KEY_L                  => 'l',
	GLFW.KEY_M                  => 'm',
	GLFW.KEY_N                  => 'n',
	GLFW.KEY_O                  => 'o',
	GLFW.KEY_P                  => 'p',
	GLFW.KEY_Q                  => 'q',
	GLFW.KEY_R                  => 'r',
	GLFW.KEY_S                  => 's',
	GLFW.KEY_T                  => 't',
	GLFW.KEY_U                  => 'u',
	GLFW.KEY_V                  => 'v',
	GLFW.KEY_W                  => 'w',
	GLFW.KEY_X                  => 'x',
	GLFW.KEY_Y                  => 'y',
	GLFW.KEY_Z                  => 'z',
	GLFW.KEY_LEFT_BRACKET       => '[',
	GLFW.KEY_BACKSLASH          => Char(92),
	GLFW.KEY_RIGHT_BRACKET      => ']',
	GLFW.KEY_GRAVE_ACCENT       => Char(96),
    )
    if key in keys(keydict)
        return keydict[key]
    end
    return key
end



##############################################################################
# gl types

gltype(T::Type{Float32}) = GL_FLOAT
gltype(T::Type{UInt32}) = GL_UNSIGNED_INT
gltype(T::Type{UInt8}) = GL_UNSIGNED_BYTE
gltype(x::Bool) = x ? GL_TRUE : GL_FALSE


##############################################################################
# index buffer

struct IndexBuffer
    id::UInt64
    count
end

function make_index_buffer(data::Array{UInt32, 1})
    # Create the Index Buffer Object (VBO)
    ibo = jglGenBuffers(1)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo[1])  # select this buffer
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW)
    count = length(data)
    return IndexBuffer(ibo[1], count)
end

bind(ib::IndexBuffer) =  glBindBuffer(GL_ARRAY_BUFFER, ib.id)  # select this buffer
unbind(ib::IndexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, 0)
del(ib::IndexBuffer) = glDeleteBuffers(1, UInt32[ib.id])


##############################################################################
# vertex buffer


struct VertexBuffer
    id::UInt64
end

function make_vertex_buffer(data::Array{Float32, 1})
    # Create the Vertex Buffer Object (VBO)
    vbo = jglGenBuffers(1)
    glBindBuffer(GL_ARRAY_BUFFER, vbo[1])  # select this buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW)
    return VertexBuffer(vbo[1])
end

function make_dynamic_vertex_buffer(datasize::UInt64)
    # Create the Vertex Buffer Object (VBO)
    # this just allocates on the GPU, doesn't need the data
    vbo = jglGenBuffers(1)
    glBindBuffer(GL_ARRAY_BUFFER, vbo[1])  # select this buffer
    glBufferData(GL_ARRAY_BUFFER, datasize, C_NULL, GL_DYNAMIC_DRAW)
    return VertexBuffer(vbo[1])
end



bind(vb::VertexBuffer) =  glBindBuffer(GL_ARRAY_BUFFER, vb.id)  # select this buffer
unbind(vb::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, 0)
del(vb::VertexBuffer) = glDeleteBuffers(1, UInt32[vb.id])





##############################################################################
# vertex buffer layout

struct VertexBufferElement
    etype
    count
    normalized
end

mutable struct VertexBufferLayout
    elements
    stride::UInt64
end

function Base.push!(vbl::VertexBufferLayout, T::Type, count)
    nrm = false
    if isa(T, UInt8)
        nrm = true
    end
    push!(vbl.elements, VertexBufferElement(T, count, nrm))
    vbl.stride += sizeof(T)*count
end

function add_buffer(vb::VertexBuffer, layout::VertexBufferLayout)
    bind(vb)
    i = 0
    offset = 0
    for elt in layout.elements
        glEnableVertexAttribArray(i)
        glVertexAttribPointer(i, elt.count, gltype(elt.etype), gltype(elt.normalized),
                              layout.stride, Ptr{Nothing}(offset))
        offset += elt.count * sizeof(elt.etype)
        i += 1
    end
end

make_vertex_buffer_layout() = VertexBufferLayout(Any[], 0)


##############################################################################
# vertex array

# vao specifies the layout of the vbo
# Necessary for core profile
# can be left out if using the compat profile
#
# usually we use a vao for each piece of geometry
# alternatively, one can use a single vao, and bind
# a vbo and setup the attribarray for each piece of geometry
# the vao will contain a link to the vbo and the vertex attribs

mutable struct VertexArray
    id
end
function make_vertex_array()
    vao =  jglGenVertexArrays(1)
    return VertexArray(vao[1])
end

bind(va::VertexArray) =  glBindVertexArray(va.id)
unbind(va::VertexArray) =  glBindVertexArray(0)

##############################################################################
# shader

function vshader()
    s = """
#version 450 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 texCoord;
layout(location = 2) in float texIndex;
layout(location = 3) in vec4 color;

out vec2 v_TexCoord;   // a varying
out float v_TexIndex;
out vec4 v_Color;

uniform mat4 u_MVP;

void main()
{
  gl_Position = u_MVP * position;
  v_TexCoord = texCoord;
  v_TexIndex = texIndex;
  v_Color = color;
}
"""
    return s
end

function fshader()
    s = """
#version 450 core

layout(location = 0) out vec4 color;

in vec2 v_TexCoord;
in float v_TexIndex;


uniform vec4 u_Color;
uniform sampler2D u_Texture[32];

void main()
{
  int index = int(v_TexIndex);
  vec4 texColor = texture(u_Texture[index], v_TexCoord);
  color = texColor;
  
}
"""
    return s
end
    




mutable struct Shader
    id
    locations
end


function make_shader()
    vertex_shader_src = vshader()
    fragment_shader_src = fshader()
    id = create_shaders(vertex_shader_src, fragment_shader_src)
    locs = Dict()
    return Shader(id, locs)
end

function location(sh::Shader, name)
    if !(name in keys(sh.locations))
        location = glGetUniformLocation(sh.id, name)
        sh.locations[name] = location
    end
    return sh.locations[name]
end


set_uniform(sh::Shader, name, v1::Int32) =  glUniform1i(location(sh,name), v1)
set_uniform(sh::Shader, name, v1::Float32) =  glUniform1f(location(sh,name), v1)

function set_uniform(sh::Shader, name, T::Array{Float32,2})
    glUniformMatrix4fv(location(sh, name), 1, GL_FALSE, T)
end

function set_uniform(sh::Shader, name, x::Array{Int32,1})
    glUniform1iv(location(sh, name), length(x), x)
end

bind(sh::Shader) = glUseProgram(sh.id)


##############################################################################

function compile_shader(shtype, src)
    id = glCreateShader(shtype)
    jglShaderSource(id, src)
    glCompileShader(id)
    result = jglGetShaderiv(id, GL_COMPILE_STATUS)
    if result == 0
        len = jglGetShaderiv(id, GL_INFO_LOG_LENGTH)
        log = jglGetShaderInfoLog(id, len)
        println("Shader compile failed. Log = ", log)
        glDeleteShader(id)
        return 0 
    end
    return id
end
                        
function create_shaders(vertex_shader_src, fragment_shader_src)
    vs = compile_shader(GL_VERTEX_SHADER, vertex_shader_src)
    fs = compile_shader(GL_FRAGMENT_SHADER, fragment_shader_src)
    program = glCreateProgram()
    glAttachShader(program, vs)
    glAttachShader(program, fs)
    glLinkProgram(program)
    linked = jglGetProgramiv(program, GL_LINK_STATUS)
    if linked == 0
        len = jglGetProgramiv(program, GL_INFO_LOG_LENGTH)
        log = jglGetProgramInfoLog(program, len)
        println("link failed: log = ", log)
    end
    glValidateProgram(program)
    glDeleteShader(vs)
    glDeleteShader(fs)
    return program
end


#function readfile(filename)
#    io = open(filename)
#    c = read(io, String)
#    close(io)
#    return c
#end

##############################################################################
# opengl errors
# 
# function clear_gl_errors()
#     while (glGetError() != GL_NO_ERROR)
#     end
# end
# 
# function check_gl_errors()
#     while true
#         e = glGetError()
#         if e == GL_NO_ERROR
#             break
#         end
#         println("Open GL error: ", e)
#     end
# end

##############################################################################
# julia functions to abstract away pointers

                                        
                                        
function jglGetShaderiv(shader, pname)
    compiledarray = Int32[0]
    glGetShaderiv(shader, pname, compiledarray) 
    return compiledarray[1]
end

function jglGetProgramiv(program, pname)
    paramsarray = Int32[0]
    glGetProgramiv(program, pname, paramsarray)
    return paramsarray[1]
end

function jglGetShaderInfoLog(shader, maxlen)
    logarray = zeros(UInt8, maxlen+1)
    lengtharray = Int64[0]
    glGetShaderInfoLog(shader, maxlen, lengtharray, logarray)
    logarray[end] = 0
    log = unsafe_string(pointer(logarray), maxlen)
    return log
end

function jglGetProgramInfoLog(program, maxlen)
    logarray = zeros(UInt8, maxlen+1)
    lengtharray = UInt8[0]
    glGetProgramInfoLog(program, maxlen, lengtharray, logarray);
    logarray[end] = 0
    log = unsafe_string(pointer(logarray), maxlen)
    return log
end

function jglShaderSource(id, src)
    shader_code_ptrs = Ptr{UInt8}[pointer(src)]
    len = Ref{Int32}(length(src))
    glShaderSource(id, 1, shader_code_ptrs, len)
end

# returns an array of ints
function jglGenVertexArrays(n)
    vao = zeros(GLuint, n)
    glGenVertexArrays(n, vao)
    return vao
end

# returns an array of ints
function jglGenBuffers(n)
    vbo = zeros(GLuint, n)
    glGenBuffers(n, vbo)
    return vbo
end

function jglGenTextures(n)
    tex = zeros(GLuint, n)
    glGenTextures(n, tex)
    return tex
end

##############################################################################
# utils


# orthographic proj
# constructs a projection matrix such that
# the window coords are left,right,top,bottom
function ortho(left, right, bottom, top, near, far)
    tx = -(right+left)/(right-left)
    ty = -(top+bottom)/(top-bottom)
    tz = -(far + near)/(far-near)
    T = [2/(right-left)  0  0  tx;
         0  2/(top-bottom)  0  ty;
         0  0  -2/(far-near)   tz;
         0 0 0 1]
    #
    #  This maps to normalized device coords (-1 to 1)
    #  T * [right, top, 0, 1] = [1,1,0,1]
    #  T * [left, bottom, 0, 1] = [-1,-1,0,1]
    #
    return convert.(Float32, T)
end


##############################################################################

mutable struct Renderer
    vertex_array
    vertex_buffer
    index_buffer
    shader
    stride   # number of bytes per vertex
    vertices
end

function make_renderer(width,height)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_BLEND)

    # make the VERTEX ARRAY 
    va = make_vertex_array()
    bind(va)

    vbl = make_vertex_buffer_layout()
    push!(vbl, Float32, 2)  # pos takes 2 floats
    push!(vbl, Float32, 2)  # texcoords 2 floats
    push!(vbl, Float32, 1)  # texslot 1 float

    # make the VERTEX BUFFER, and attach
    num_vertices = 4
    stride = vbl.stride  # number of bytes per vertex
    vb = make_dynamic_vertex_buffer(stride*num_vertices)
    add_buffer(vb, vbl)

    # make the INDEX BUFFER
    # pattern of vertices
    # two triangles for each quad
    indices = UInt32[0,1,2,2,3,0]
    ib = make_index_buffer(indices)

    # make the SHADER
    shader = make_shader()
    bind(shader)
    set_uniform(shader, "u_Texture", Int32[0])
    
    bren = Renderer(va, vb, ib, shader, stride, 0)
    bind(bren.shader)
    make_polygon(bren, width, height)
    

    bind(bren.vertex_array)
    bind(bren.index_buffer)
    return bren
end

function PlotKitCairo.draw(bren::Renderer, tex)
    unitbind(tex, 0)
    bind(bren.vertex_buffer)
    vertex_count = 4
    index_count = 6
    glBufferSubData(GL_ARRAY_BUFFER, 0, bren.stride * vertex_count, bren.vertices)
    glDrawElements(GL_TRIANGLES, index_count, GL_UNSIGNED_INT, C_NULL)
end

function clear(bren::Renderer)
    glClear(GL_COLOR_BUFFER_BIT)
end

function PlotKitCairo.draw(bren::Renderer, pik::Pik)
    tex = Texture(pik)
    draw(bren, tex)
    unbind(tex)
    del(tex)
end

##############################################################################
# for cairo

mutable struct CairoWindow
    window
    bren
    pik
    surface
    ctx
    width
    height
    resizable::Bool
    resized::Bool
end

function CairoWindow(width, height; storewidth=nothing, storeheight=nothing,
                     resizable = false)
    window = Window(width,height)
    resized = resizable
    cw  = CairoWindow(window,0,0,0,0,width,height, resizable, resized)
    makestore(cw; storewidth, storeheight)
    function resized_cb(glwin, width, height)
        cw.resized = true
        cw.width = width
        cw.height = height
    end
    GLFW.SetWindowSizeCallback(cw.window.glfw_window, resized_cb)
    return cw
end

function init(cw::CairoWindow)
    fixtitle_post_window_creation(cw)
    window = cw.window
    cw.bren = make_renderer(window.width, window.height)
    return cw
end

function fixtitle_pre_window_creation()
    GLFW_X11_INSTANCE_NAME = 0x00024002
    GLFW_X11_CLASS_NAME =  0x00024001
    GLFW.WindowHintString(GLFW_X11_INSTANCE_NAME, "cairogl")
    GLFW.WindowHintString(GLFW_X11_CLASS_NAME, "cairogl")
end

function fixtitle_post_window_creation(cw)
    # window will not show in google meet, for example
    # because of this issue:
    # https://github.com/libsdl-org/SDL/issues/4924
    # glfw sets NET_WM_NAME but not WM_NAME
    
    # fix using
    #  xdotool selectwindow set_window --name "WindowName"
    #
    # Note cairogl sets the window title, which we use to
    # search for the window
    #
    window_name = "singleviewer"
    GLFW.SetWindowTitle(cw.window.glfw_window, window_name)
    cmd = Any["/usr/bin/xdotool", "search", "--class", "cairogl", "set_window", "--name", window_name]
    run(`$cmd`)
end


##############################################################################
# resizing



# call this         ctx = checkresized(cw)
# at the beginning of the event loop
function checkresized(cw::CairoWindow; storewidth = nothing, storeheight = nothing)
    if !cw.resizable || !cw.resized
        return cw.ctx, false
    end
    Cairo.finish(cw.surface)
    makestore(cw; storewidth, storeheight)
    resize(cw.window, cw.width, cw.height)
    make_polygon(cw.bren, cw.width, cw.height)
    resizegl(cw.width, cw.height)
    cw.resized = false
    return cw.ctx, true
end


function makestore(cw::CairoWindow; storewidth = nothing, storeheight = nothing)
    if storewidth == nothing
        storewidth = cw.width
    end
    if storeheight == nothing
        storeheight = cw.height
    end
    cw.pik, cw.surface, cw.ctx = cairo_memory_surface_ctx(storewidth, storeheight)
end

function resize(cglwin::Window, width, height)
    cglwin.width = width
    cglwin.height = height
end

# width, height = window size in pixels
# width/scale, height/scale  = size of backing store
#
# If we already have a polygon, and change it's size, then 
# this doesn't do anything noticeable, because the vertices
# map to the of the window in normalized device coords [-1,1]
# This changes the coordinates of the vertices, but also
# changes the projection matrix, so after doing this the vertices
# still map to the corners. Since we only use one polygon,
# and map a texture to it (in texture coords)
#
# But if we decide in future to put additional polygons on the
# screen, this ensures that the coordinate system we use
# will match screen pixels.
#
function make_polygon(bren::Renderer, width, height)
    x = 0
    y = 0
    # in textures, 0,0 is at the bottom
    # in Cairo, 0,0 is at the top
    # we fix this using the texture coordinates
    vertices = Float32[x,       y,        0.0, 1.0, 0.0,
                       x+width, y,        1.0, 1.0, 0.0,
                       x+width, y+height, 1.0, 0.0, 0.0,
                       x,       y+height, 0.0, 0.0, 0.0]
    bren.vertices = vertices
    proj = CairoGL.ortho(0, width, 0, height, -1, 1)
    set_uniform(bren.shader, "u_MVP", proj)
end

resizegl(width, height) = glViewport(0,0,width,height)


function setsize(cw::CairoWindow, width, height)
    GLFW.SetWindowSize(cw.window.glfw_window, Int(round(width)), Int(round(height)))
end

##############################################################################


closed(cw::CairoWindow) = closed(cw.window)
Base.close(cw::CairoWindow) = finish(cw.window)
swap(cw::CairoWindow) = swap(cw.window)
PlotKitCairo.draw(cw::CairoWindow) = draw(cw.bren, cw.pik)
key(cw::CairoWindow, k) = key(cw.window, k)

end
