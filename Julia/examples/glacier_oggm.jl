# Let's retrieve some more data from OGGM for one of the glaciers!
using Pkg; Pkg.activate(".")


using ExploreODINN
# include("../src/ExploreODINN.jl")
using Sleipnir, Huginn
using Plots
using Plots.PlotMeasures
using MakieCore: heatmap
using CairoMakie
using Statistics
using Rasters
using Dates
using PythonCall

working_dir = joinpath(homedir(), ".ODINN/ODINN_prepro")

# Bossons glacier
rgi_ids = ["RGI60-11.03646"] 

# Aletschgletscher
# rgi_ids = ["RGI60-11.01450"] 

# Glacier d’Argentière
# rgi_ids = ["RGI60-11.03638"] 

# Glacier Mar de Glace
# rgi_ids = ["RGI60-11.03643"] 

# rgi_ids = ["RGI60-11.00872"]

# Perito Moreno 
# rgi_ids = ["RGI60-17.00312"] 

# Fix this
rgi_paths = get_rgi_paths()
# rgi_paths = Dict("RGI60-11.03643" => "per_glacier/RGI60-11/RGI60-11.03/RGI60-11.03643")
rgi_paths = Dict(k => rgi_paths[k] for k in rgi_ids)

params = Huginn.Parameters(simulation = SimulationParameters(use_MB=false,
                                                          velocities=false,
                                                          tspan=(2010.0, 2015.0),
                                                          working_dir = working_dir,
                                                          multiprocessing = false,
                                                        #   working_dir = Huginn.root_dir,
                                                          test_mode = true,
                                                          rgi_paths = rgi_paths),
                        solver = SolverParameters(reltol=1e-12)
                        )

# Define new model
model = Huginn.Model(iceflow = SIA2Dmodel(params), mass_balance = nothing)

# We retrieve some glaciers for the simulation
glaciers = initialize_glaciers(rgi_ids, params)

# Let's grab a single glacier
glacier = glaciers[1]

lats = glacier.Coords["lat"]
lons = glacier.Coords["lon"]

# Ice Surface Velocity Data

nc_file_multi = "../../data/DATASET_FACU/c_x01225_y03675_all_filt-multi.nc"
ice_surface_data = preprocessing(nc_file_multi)

v_count = mean((ice_surface_data.vabs .!== 0.0) .* (.!isnan.(ice_surface_data.vabs)), dims=3)[:,:,1]

# Python Plot

fig, axes = plt[].subplots()
fig.set_size_inches(10, 10)
caxes = axes.inset_axes([1.04, 0.06, 0.03, 0.4])

# axes.set_aspect("equal")
axes.set_xlabel("Longitude")
axes.set_ylabel("Latitude")
axes.spines[pylist(["right", "top"])].set_visible(false)

xs = lons #range(1, 48, length=48)
ys = lats # range(1, 79, length=79)
xs_mesh = xs' .* ones(length(ys))
ys_mesh = ones(length(xs))' .* ys

Δdist = 0.4 * (glacier.Δx^2 + glacier.Δy^2)^0.5

H_masked = copy(glacier.H₀)
H_masked[H_masked .< 0.01] .= NaN

# V_abs = (glacier.Vx.^2 + glacier.Vy.^2).^0.5
# V_abs[glacier.H₀ .< 0.01] .= NaN

# H_masked = np[].ma.array(glacier.H₀', mask=0.0)

# ColorGrid = axes.pcolormesh(xs_mesh, ys_mesh, H_masked', alpha=0.20)
# ColorGrid = axes.pcolormesh(xs_mesh, ys_mesh, H_masked', alpha=0.20)
ColorGrid = axes.pcolormesh(ice_surface_data.lon, ice_surface_data.lat, v_count, alpha=0.70)
# axes.scatter(ice_surface_data.lon', ice_surface_data.lat', s=1.0, c="k")
# ColorGrid = axes.pcolormesh(xs_mesh, ys_mesh, V_abs', alpha=0.95)

ContourLines = axes.contour(xs_mesh, ys_mesh, H_masked', 20, colors='k', levels=[Δdist, 50, 100, 150, 200, 250])  

cbar = plt[].colorbar(ColorGrid, cax=caxes, orientation="vertical")

plt[].savefig("./figures/thickness.pdf", dpi=300, format="pdf", bbox_inches="tight")


# Temperature plot
plot_temp = Plots.plot(glacier.climate.raw_climate[At(DateTime(2012):Day(1):DateTime(2019))][:temp])
Plots.savefig(plot_temp, "./figures/temperature.pdf")
# plt[].savefig("./figures/temperature.pdf", dpi=300, format="pdf", bbox_inches="tight")

# Precipitation plot
plot_prcp = Plots.plot(glacier.climate.raw_climate[At(DateTime(2012):Day(1):DateTime(2019))][:prcp])
# plt[].savefig("./figures/precipitation.pdf", dpi=300, format="pdf", bbox_inches="tight")
Plots.savefig(plot_prcp, "./figures/precipitation.pdf")





# Now, let's plot the contours of the glacier on top of an image 

