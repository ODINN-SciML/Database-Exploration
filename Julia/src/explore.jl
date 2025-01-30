using Pkg; Pkg.activate(".")

using NetCDF
using Dates, DateFormats
using Statistics
using Plots
using Plots.PlotMeasures

# Data corresponding to Mont Blanc Massif

# Raw data? 
nc_file_multi = "../../data/DATASET_FACU/c_x01225_y03675_all_filt-multi.nc"

# Interpolated dataset 
nc_file_interp = "../../data/DATASET_FACU/c_x01225_y03675_interp.nc"

# nc_file = nc_file_interp
nc_file = nc_file_multi

# all the information of the NetCDF file is included here
@show ncinfo(nc_file)

# Accessing attributes
notes = ncgetatt(nc_file, "global", "Notes")
@show notes

xs = ncread(nc_file, "x")
ys = ncread(nc_file, "y")

# Velocity in the x direction (m/yr)
vx = ncread(nc_file, "vx")              
vx_error = ncread(nc_file_multi, "error_vx")
vy = ncread(nc_file, "vy")              
vy_error = ncread(nc_file_multi, "error_vy")

v_abs = (vx.^2 .+ vy.^2).^0.5
# This is not really how to compute the error, but good enouth proxy
v_abs_dense_error = (vx_error.^2 .+ vy_error.^2 ).^0.5

# Date of first adquisition
date1_raw = ncread(nc_file, "date1")
# Date of second adquisition
date2_raw = ncread(nc_file, "date2")

# Middle date
# Depending the dataset, we obtain dates and middle dates differently
if nc_file == "../../data/DATASET_FACU/c_x01225_y03675_all_filt-multi.nc"
    date_mean_raw = 0.5 .* date1_raw .+ 0.5 .* date2_raw
    date_mean_offset = date1_offset = date2_offset = 0
elseif nc_file == "../../data/DATASET_FACU/c_x01225_y03675_interp.nc"
    date_mean_raw = ncread(nc_file, "mid_date")
    date_mean_offset = datetime2julian(DateTime("2015-08-14")) - 2400000.5
    date1_offset = datetime2julian(DateTime("2015-07-30")) - 2400000.5
    date2_offset = datetime2julian(DateTime("2015-08-29")) - 2400000.5
end 

# Convert dates from Modified Julian Days to datetipes
date1 = mjd.(date1_raw .+ date1_offset)
date2 = mjd.(date2_raw .+ date2_offset)
date_mean = mjd.(date_mean_raw .+ date_mean_offset)
date_error = date2 .- date1

nx, ny, ntimes = size(vx)
@assert length(date1) == length(date2) == ntimes

# compute average velocities 

v_mean = Float64[]
v_std = Float64[]

for i in 1:ntimes
    v_nonzero = v_abs[:,:,i][v_abs[:,:,i] .>= 0.010]
    μ = mean(v_nonzero)
    σ = std(v_nonzero)
    push!(v_mean, μ)
    push!(v_std, σ)
end

# Plot Velocities 

plot_vx = Plots.scatter(date1, v_mean, label="V", yerr=v_std[1:100], ms=5, msw=0.3)
plot!(fontfamily="Computer Modern",
     #title="PIL51",
    titlefontsize=18,
    tickfontsize=15,
    legendfontsize=15,
    guidefontsize=18,
    #ylimits=(0.1,10),
    #xlimits=(10^(-4),10^(-1)),
    legend=true,
    margin= 7mm,
    size=(1200,500),
    dpi=600)

Plots.savefig(plot_vx, "figures/vx.pdf")

using MakieCore: heatmap
using CairoMakie

id_date = 70
@show date1[id_date]


zs1 = vx[:, :, id_date]
zs2 = vy[:, :, id_date]
zs3 = v_abs[:, :, id_date]

# Bossons Glacier
# idx, idy = 165, 95
# Brenva Glacier 
idx, idy = 225, 235

vmax = maximum(x -> isnan(x) ? -Inf : x, zs3)

# zs3 = replace!(x -> x==0.0 ? NaN : x, Array{Union{Float64, Nothing}}(zs3))
zs1 = replace!(x -> x==0.0 ? NaN : x, zs1)
zs2 = replace!(x -> x==0.0 ? NaN : x, zs2)
zs3 = replace!(x -> x==0.0 ? NaN : x, zs3)

joint_limits = (-vmax, vmax)  # here we pick the limits manually for simplicity instead of computing them
abs_limits = (0, vmax)

fig = Figure(size=(2000, 600), axis=(;title="dsds"));

ax1, hm1 = heatmap(fig[1,1], xs, ys, zs1,  colorrange = abs_limits, colormap = Reverse(:acton25), nan_color = :transparent, axis=(; title="V Abs (Data: $(date1[id_date]))"));
ax2, hm2 = heatmap(fig[1, end+1], xs, ys, zs2, colorrange = joint_limits, colormap = :broc25, axis=(; title="Vx"));
ax3, hm3 = heatmap(fig[1, end+1], xs, ys, zs3, colorrange = joint_limits, colormap = :broc25, axis=(; title="Vy"));

# CairoMakie.scatter!(ax1, Point(xs[idx], ys[idy]); marker='🦜', markersize=40, color = :purple)
CairoMakie.scatter!(ax1, Point(xs[idx], ys[idy]); marker='x', markersize=40, color = :purple)

# Colorbar(fig[:, end+1], hm1)                     # These three
# Colorbar(fig[:, end+1], hm2)                     # colorbars are
Colorbar(fig[:, end+1], hm1);                      # colorbars are
Colorbar(fig[:, end+1], hm2);  # equivalent

save("figures/v_heatmap.pdf", fig)


# Let's see the counting of data points 

fig_count = Figure(size=(800, 600), axis=(;title="dsds"));

v_count = mean((v_abs .!== 0.0) .* (.!isnan.(v_abs)), dims=3)[:,:,1]

ax_ct, hm = heatmap(fig_count[1,1], v_count, colorrange=(0.0, 1.0))
Colorbar(fig_count[:, end+1], hm);                      # colorbars are

save("figures/v_count.pdf", fig_count)


#######################################


# Let's make a plot with the timeseries with more records
v_abs_dense = v_abs[idx, idy, :]

yrs = 2015:2021
mealt_max = [DateTime("$(yr)-08-01") for yr in yrs]
mealt_max_raw = Dates.datetime2julian.(mealt_max) .- 2400000.5
mealt_max = Date.(mealt_max)

# Error bars here make no sense! Figure this out
plot_vx = Plots.scatter(date_mean_raw, v_abs_dense, label="V", yerr=v_abs_dense_error, ms=3, msw=0.01)
# plot_vx = Plots.scatter(date_mean, v_abs_dense, label="Absolute ice surface velocity (interpolation)", ms=2)

for i in 1:length(date_mean)
    plot!(plot_vx, [date1_raw[i], date2_raw[i]], [v_abs_dense[i], v_abs_dense[i]], lw=0.2, lc=:black, legend=false)
end 

vline!(mealt_max_raw, label="August 1st")

plot!(fontfamily="Computer Modern",
     title="Ice Surface Velocities",
    titlefontsize=18,
    tickfontsize=15,
    legendfontsize=15,
    guidefontsize=18,
    xlabel="Date",
    ylabel="Velocity (m/yr)",
    xticks=(mealt_max_raw, mealt_max),
    ylimits=(200,450),
    #xlimits=(10^(-4),10^(-1)),
    legend=false,
    margin= 10mm,
    size=(1400,500),
    dpi=600)


Plots.savefig(plot_vx, "figures/vabs_dense.pdf")

### Let's identify all the indices for which there is a good covering