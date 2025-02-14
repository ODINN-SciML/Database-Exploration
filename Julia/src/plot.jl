export plot_timeseries, plot_count

function plot_timeseries(data::AbstractData, idx::Int, idy::Int; ignore_zeros=false, saveas::Union{Nothing, String}=nothing)

    vabs = data.vabs[idx, idy, :]

    # Define begining of hydrologic year
    yrs = 2015:2021
    mealt_max = [DateTime("$(yr)-08-01") for yr in yrs]
    mealt_max_raw = Dates.datetime2julian.(mealt_max) .- 2400000.5
    mealt_max = Date.(mealt_max)

    date_raw = Dates.datetime2julian.(data.date) .- 2400000.5
    date1_raw = Dates.datetime2julian.(data.date1) .- 2400000.5
    date2_raw = Dates.datetime2julian.(data.date2) .- 2400000.5

    # Unfortunately, Plots does not support horizonal error bar in Date format, so 
    # we do this manually for now...

    if ignore_zeros
        vmax = maximum(vabs[vabs .> 0.0])
        vmin = minimum(vabs[vabs .> 0.0])
    else
        vmax = maximum(vabs)
        vmin = minimum(vabs)
    end

    _plot = Plots.scatter(date_raw, vabs, label="Velocity", yerr=data.vabs_error, ms=3, msw=0.01)

    for i in 1:length(date_raw)
        Plots.plot!(_plot, [date1_raw[i], date2_raw[i]], [vabs[i], vabs[i]], lw=0.2, lc=:black, legend=false)
    end 

    vline!(mealt_max_raw, label="August 1st")

    Plots.plot!(fontfamily="Computer Modern",
                title="Ice Surface Velocities",
                titlefontsize=18,
                tickfontsize=15,
                legendfontsize=15,
                guidefontsize=18,
                xlabel="Date",
                ylabel="Velocity (m/yr)",
                xticks=(mealt_max_raw, mealt_max),
                ylimits=(vmin,vmax),
                #xlimits=(10^(-4),10^(-1)),
                legend=false,
                margin= 10mm,
                size=(1400,500),
                dpi=600)

    if isnothing(saveas)
        return plot 
    else
        Plots.savefig(_plot, saveas)
    end
end

"""

"""
function plot_count(data::AbstractData; saveas::Union{Nothing, String}=nothing)

    fig_count = Figure(size=(800, 600), axis=(;title="Counts"));

    v_count = mean((data.vabs .!== 0.0) .* (.!isnan.(data.vabs)), dims=3)[:,:,1]

    max_count = maximum(v_count)

    ax_ct, hm = heatmap(fig_count[1,1], v_count, colorrange=(0.0, max_count));
    Colorbar(fig_count[:, end+1], hm);     

    if isnothing(saveas)
        return fig_count
    else
        save(saveas, fig_count)  
    end
end