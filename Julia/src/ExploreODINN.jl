__precompile__()
module ExploreODINN

using Dates, DateFormats
using NetCDF

using Plots
using Plots.PlotMeasures
using MakieCore: heatmap
using CairoMakie

using Statistics

using PythonCall, CondaPkg

using Infiltrator

using Unitful: m, rad, °
using CoordRefSystems
using Sleipnir

include("./utils.jl")
include("./data.jl")
include("./preprocessing.jl")
include("./plot.jl")

# We define empty objects for the Python packages
const mpl_base = Ref{Py}()
const mpl_colors = Ref{Py}()
const mpl_colormap = Ref{Py}()
const plt = Ref{Py}()
const sns = Ref{Py}()
const ccrs = Ref{Py}()
const feature = Ref{Py}()
const np = Ref{Py}()

include("./setup/config.jl")

end
