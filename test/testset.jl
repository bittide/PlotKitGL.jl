
plotpath(x) = joinpath(ENV["HOME"], "plots/", x)

function main()
    @testset "PlotKitGL" begin
        @test main1()
        @test main2()
        @test main3()
    end
end

pzip(a,b) = Point.(zip(a,b))

function plot(data; kw...)
    ad = AxisDrawable(data; kw...)
    drawaxis(ad)
    line(ad, data; linestyle = LineStyle(Color(:red),1))
    return ad # close handled by caller
end

# a simple animated plot
function main1()
    println("main1")
    x = collect(0:0.01:10)
    pf(t) = pzip(x, sin.(x *(1+t)))
    ff(t) = plot(pf(t); ymin =-2, ymax = 2,
                 windowbackgroundcolor = Color(1-exp(-t),0.8,0.8))
    anim = Anim(ff)
    anim.tmax = 5
    see(anim)
    return true
end

# a simple animated plot, saving a frame
function main2()
    println("main2")
    x = collect(0:0.01:10)
    pf(t) = pzip(x, sin.(x *(1+t)))
    ff(t) = plot(pf(t); ymin =-2, ymax = 2,
                 windowbackgroundcolor=Color(1-exp(-t),0.8,0.8))
    anim = Anim(ff)
    save(frame(anim, 1.2), plotpath("test_plotkitgl2.png"))
    anim.tmax = 1
    see(anim)
    return true
end

# using the animator to show a fixed plot
function main3()
    x = -0.1:0.1:1.3
    y = x.*x
    see(plot(pzip(x,y); tmax = 1))
    return true
end
