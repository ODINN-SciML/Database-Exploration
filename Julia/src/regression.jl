"""

Function to generate regression model for trend and seasonality

Coefficients for OLS regression are:
    - Intercept
    - Slope 
    - Sin component
    - Cos component
"""
function regress(data::AbstractData, idx::Int, idy::Int)

    vabs = data.vabs[idx, idy, :]
    n = length(vabs)

    time = data.time

    # Day of the year for periodic signal
    doy = Dates.dayofyear.(data.date) ./ 365
    
    # Coefficients for OLS regression are 
    X = [ ones(n); time; sin.(2π .* doy); cos.(2π .* doy)]

    # Contruct OLS estimatior... 

end