using Pkg; Pkg.activate(".")
using ExploreODINN

# Exploration of Glacier data is done with OGGM: https://tutorials.oggm.org/stable/notebooks/tutorials/working_with_rgi.html
# As there explained, we can find an individual glacier using the GLIMS glacier viewer: https://www.glims.org/maps/glims


# Data corresponding to Mont Blanc Massif
# Raw data
nc_file_multi = "../../data/DATASET_FACU/c_x01225_y03675_all_filt-multi.nc"
# Interpolated dataset 
nc_file_interp = "../../data/DATASET_FACU/c_x01225_y03675_interp.nc"

# Read the dataset
data = preprocessing(nc_file_multi)

# Let's make a plot with the timeseries for a grid point with good measurement

# Bossons Glacier
# idx, idy = 165, 95
# Brenva Glacier 
idx, idy = 225, 235

plot_timeseries(data, idx, idy; ignore_zeros=true, saveas="figures/timeseries_vabs.pdf")
plot_timeseries(data, idx-1, idy+1; ignore_zeros=true, saveas="figures/timeseries_vabs_2.pdf")
plot_timeseries(data, idx+1, idy-1; ignore_zeros=true, saveas="figures/timeseries_vabs_3.pdf")


# Plot the total number of observations
plot_count(data, saveas="figures/v_count.pdf");


# facubsapienza
# FacuEarthData_2025






















# id_date = 70
# @show date1[id_date]


# zs1 = vx[:, :, id_date]
# zs2 = vy[:, :, id_date]
# zs3 = v_abs[:, :, id_date]

# vmax = maximum(x -> isnan(x) ? -Inf : x, zs3)

# # zs3 = replace!(x -> x==0.0 ? NaN : x, Array{Union{Float64, Nothing}}(zs3))
# zs1 = replace!(x -> x==0.0 ? NaN : x, zs1)
# zs2 = replace!(x -> x==0.0 ? NaN : x, zs2)
# zs3 = replace!(x -> x==0.0 ? NaN : x, zs3)

# joint_limits = (-vmax, vmax)  # here we pick the limits manually for simplicity instead of computing them
# abs_limits = (0, vmax)

# fig = Figure(size=(2000, 600), axis=(;title="dsds"));

# ax1, hm1 = heatmap(fig[1,1], xs, ys, zs1,  colorrange = abs_limits, colormap = Reverse(:acton25), nan_color = :transparent, axis=(; title="V Abs (Data: $(date1[id_date]))"));
# ax2, hm2 = heatmap(fig[1, end+1], xs, ys, zs2, colorrange = joint_limits, colormap = :broc25, axis=(; title="Vx"));
# ax3, hm3 = heatmap(fig[1, end+1], xs, ys, zs3, colorrange = joint_limits, colormap = :broc25, axis=(; title="Vy"));

# # CairoMakie.scatter!(ax1, Point(xs[idx], ys[idy]); marker='🦜', markersize=40, color = :purple)
# CairoMakie.scatter!(ax1, Point(xs[idx], ys[idy]); marker='x', markersize=40, color = :purple)

# # Colorbar(fig[:, end+1], hm1)                     # These three
# # Colorbar(fig[:, end+1], hm2)                     # colorbars are
# Colorbar(fig[:, end+1], hm1);                      # colorbars are
# Colorbar(fig[:, end+1], hm2);  # equivalent

# save("figures/v_heatmap.pdf", fig)


