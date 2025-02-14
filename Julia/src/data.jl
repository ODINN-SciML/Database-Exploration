export AbstractData, Data

abstract type AbstractData end 

@kwdef struct VelocityData{F <: AbstractFloat} <: AbstractData
    x::Vector{F}
    y::Vector{F}
    lat::Vector{F}
    lon::Vector{F}
    vx::Array{F, 3}
    vy::Array{F, 3}
    vabs
    vx_error
    vy_error
    vabs_error
    date
    date1
    date2
    date_error
    # vx_error::Union{Nothing, Vector{F}} = nothing
    # vy_error::Union{Nothing, Vector{F}} = nothing
    # vabs_error::Union{Nothing, Vector{F}} = nothing
    # date::Vector{Date}
    # date1::Vector{Date}
    # date2::Vector{Date}
    # date_error::Vector{Day}
end

