export mpl_base, mpl_colormap, mpl_colormap, plt, sns, ccrs, feature, np

function __init__()

    try
        isassigned(mpl_base) ? nothing : mpl_base[] = pyimport("matplotlib")
        isassigned(mpl_colors) ? nothing : mpl_colors[] = pyimport("matplotlib.colors")
        isassigned(mpl_colormap) ? nothing : mpl_colormap[] = pyimport("matplotlib.cm")
        isassigned(plt) ? nothing : plt[] = pyimport("matplotlib.pyplot")
        isassigned(sns) ? nothing : sns[] = pyimport("seaborn")
        isassigned(ccrs) ? nothing : ccrs[] = pyimport("cartopy.crs")
        isassigned(feature) ? nothing : feature[] = pyimport("cartopy.feature")
        isassigned(np) ? nothing : np[] = pyimport("numpy")
    catch e 
        @warn exception=(e, catch_backtrace())
    end

end