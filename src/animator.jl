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


module Animator

using Cairo
using ..PlotKitCairo
using ..CairoGL

export Anim, frame, see

mutable struct Anim
    width
    height
    speed
    tmax
    fn  # takes (ctx,t) and draws on the context
end

#
# Here, anim, takes a drawable that is a function of time
# This is the simplest thing to do.
#
# f maps t -> d::Drawable
# 
function Anim(f::Function)
    g = function(ctx, t)
        paint(ctx, f(t))
    end
    return Anim(f(0).width, f(0).height, 1, 60, g)
end



"""
    frame(anim::Anim, t)

Return a Drawable containing the animation frame at time t.
"""
function frame(anim::Anim, t)
    d = Drawable(anim.width, anim.height)
    anim.fn(d.ctx, t)
    return d
end


function see(d::Drawable; tmax = 60)
    anim = Anim(d.width, d.height, 1, tmax, (ctx,t) -> paint(ctx, d))
    see(anim)
end




function see(anim::Anim; tmax = nothing)
    win = CairoWindow(anim.width, anim.height)
    try
        mainx(win, anim; tmax)
    catch e
        println("exception")
        close(win)
        throw(e)
    end
    return
end


function mainx(win, anim; tmax = nothing)
    win = init(win)
    ctx = win.ctx
    n = 0
    t = 0
    stopped = false
    if isnothing(tmax)
        tmax = anim.tmax
    end
    while !closed(win) && t < tmax
      anim.fn(ctx, t)
      draw(win)
        dt = swap(win)
        if key(win, CairoGL.GLFW.KEY_Q) || key(win, CairoGL.GLFW.KEY_ESCAPE)
            break
        end
        if key(win, CairoGL.GLFW.KEY_SPACE)
            stopped = true
        end
        if key(win, CairoGL.GLFW.KEY_S)
            stopped = false
        end
        if !stopped
            n += 1
            if n < 5
                t = 0
            else
            t += anim.speed * dt
            end
        end
    end
    close(win)
    return
end




function mp4it(mdir, outfile)
    quality = 15
    cmd = Any["/usr/bin/ffmpeg"]
    push!(cmd, "-framerate")
    push!(cmd, 30)
    push!(cmd, "-pattern_type")
    push!(cmd, "glob")
    push!(cmd, "-i")
    push!(cmd, joinpath(mdir, "frame*.png"))
    push!(cmd, "-c:v")
    push!(cmd, "libx264")
    push!(cmd, "-pix_fmt")
    push!(cmd, "yuv420p")
    push!(cmd, "-crf")
    push!(cmd, quality)
    push!(cmd, outfile)
    run(`$cmd`)
end

function save_frames(anim::Anim, mdir)
    t = 0
    n = 0
    while t < anim.tmax
        surface = Cairo.CairoARGBSurface(anim.width, anim.height)
        ctx = Cairo.CairoContext(surface)
        anim.fn(ctx, t)
        fname = "frame_" * string(n, pad=5) * ".png"
        fname = joinpath(mdir, fname)
        println(fname)
        Cairo.write_to_png(surface, fname)
        n += 1
        t += anim.speed/30
    end
end


function Cairo.save(anim::Anim, mdir, outfile)
    save_frames(anim, mdir)
    mp4it(mdir, outfile)
end

end








