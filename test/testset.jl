

function main()
    @testset "PlotKitGL" begin
        @test main1()
    end
end

pzip(a,b) = Point.(zip(a,b))

function plot(data; kw...)
    ad = AxisDrawable(data; kw...)
    drawaxis(ad)
    line(ad, data; linestyle = LineStyle(Color(:red),1))
    return ad # what about close?    
end

function main1()
    x = collect(0:0.01:10)
    pf(t) = pzip(x, sin.(x *(1+t)))
    ff(t) = plot(pf(t); ymin =-2, ymax = 2,
                 windowbackgroundcolor = Color(1-exp(-t),0.8,0.8))
    anim = Anim(ff)
    anim.tmax = 5
    see(anim)
end


