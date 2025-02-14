export preprocessing
"""

"""
function preprocessing(file::String; interp=false)

    # all the information of the NetCDF file is included here
    @show ncinfo(file)

    # Accessing attributes
    notes = ncgetatt(file, "global", "Notes")
    @show notes

    # Temporal data
    # Date of first adquisition
    date1 = ncread(file, "date1")
    # Date of second adquisition
    date2 = ncread(file, "date2")

    # Middle date
    # Depending the dataset, we obtain dates and middle dates differently
    if !interp 
        date_mean = 0.5 .* date1 .+ 0.5 .* date2
        date_mean_offset = date1_offset = date2_offset = 0
    else 
        date_mean = ncread(file, "mid_date")
        date_mean_offset = datetime2julian(DateTime("2015-08-14")) - 2400000.5
        date1_offset = datetime2julian(DateTime("2015-07-30")) - 2400000.5
        date2_offset = datetime2julian(DateTime("2015-08-29")) - 2400000.5
    end

    # Convert dates from Modified Julian Days to datetipes
    date1 = mjd.(date1 .+ date1_offset)
    date2 = mjd.(date2 .+ date2_offset)
    date_mean = mjd.(date_mean .+ date_mean_offset)
    date_error = date2 .- date1

    # We convert from Date to DateTime
    date_mean = DateTime.(date_mean)
    date1 = DateTime.(date1)
    date2 = DateTime.(date2)

    # Read data from netcdf file
    x = ncread(file, "x")
    y = ncread(file, "y")

    # Velocity in the x direction (m/yr)
    vx = ncread(file, "vx")              
    vy = ncread(file, "vy")    

    # Compute absolute velocity
    vabs = (vx.^2 .+ vy.^2).^0.5          
    
    if !interp
        vx_error = ncread(file, "error_vx")
        vy_error = ncread(file, "error_vy")
        vabs_error = (vx_error.^2 .+ vy_error.^2 ).^0.5
    else         
        vx_error = nothing
        vy_error = nothing
        vabs_error = nothing
    end

    # Run some basic tests 
    nx, ny, ntimes = size(vx)
    @assert length(date1) == length(date2) == ntimes
    @assert nx == ny == 250

    # Spatial preprocessing
    proj_zone = ncgetatt(file, "mapping", "utm_zone_number")
    transform(X,Y) = Sleipnir.UTMercator(X, Y; zone=proj_zone, hemisphere=:north) 
    Coordinates = transform.(x, y)
    latitudes = map(x -> x.lat.val, Coordinates)
    longitudes = map(x -> x.lon.val, Coordinates)

    return VelocityData(x=x, y=y, lat=latitudes, lon=longitudes, vx=vx, vy=vy, vabs=vabs, vx_error=vx_error, vy_error=vy_error, vabs_error=vabs_error, date=date_mean, date1=date1, date2=date2, date_error=date_error)
end