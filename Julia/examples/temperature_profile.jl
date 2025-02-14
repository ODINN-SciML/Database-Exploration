using Pkg; Pkg.activate(".")

using ExploreODINN 

using DifferentialEquations
using Plots
using Plots.PlotMeasures

using Polynomials # For A fit

t = 0.2 # yr We don't need this on time
ρ = 10^3 # kg / m³
g = 9.81 # m/s²
κ = 10e-6 # m²/s
ω = 2π  # Period, 1/yr
T₀ = -25 # Celsius
ΔT = 25 # Celsius
H = 50 # m
∇S = 5 * 2π / 180 # gradians
τb = ρ * g * H * ∇S
ub = 0 # m/s
n = 3

# α = (ω / (2κ))^0.5
# Characteristical lenght
ℓ = 3.5 # m
α = 1 / ℓ

secs_in_year = 60.0 * 60.0 * 24.0 * 365.25

"""
Temperature profile
"""
function Temperature(z)
    x = H - z 
    return T₀ + ΔT * exp(-α * x) * sin(ω*t - α*x)
end

# Let's plot the vertical profile! 

zs = collect(0:0.2:H)
Ts = Temperature.(zs)

plot_T = Plots.plot(Ts, zs, label="Temperature", lw=5, ms=3, msw=0.01)
vline!([T₀-ΔT, T₀, T₀+ΔT], label="Mean and Amplitude")
Plots.plot!(fontfamily="Computer Modern", title="Temperature Profile", titlefontsize=18, tickfontsize=15,
                legendfontsize=15, guidefontsize=18, xlabel="Temperature", ylabel="Depth (m)",
                legend=false, margin= 10mm, size=(1200,1000), dpi=600)
# Plots.savefig(plot_T, "figures/temperature_profile.pdf")

"""
Dependence of Glen coefficient A with temperature
"""

const A_values_sec = ([0.0 -2.0 -5.0 -10.0 -15.0 -20.0 -25.0 -30.0 -35.0 -40.0 -45.0 -50.0;
                              2.4e-24 1.7e-24 9.3e-25 3.5e-25 2.1e-25 1.2e-25 6.8e-26 3.7e-26 2.0e-26 1.0e-26 5.2e-27 2.6e-27]) # s⁻¹Pa⁻³
# const A_values = hcat(A_values_sec[1,:], A_values_sec[2,:].*60.0*60.0*24.0*365.25)'
const A_values = hcat(A_values_sec[1,:], A_values_sec[2,:])'

A_poly = fit(A_values[1,:], A_values[2,:]) 
A_Glen(T) = A_poly(T)

plot_A = plot_velocity = Plots.plot(A_Glen.(Ts), zs, label="A", lw=5, ms=3, msw=0.01)
Plots.plot!(fontfamily="Computer Modern", title="A", titlefontsize=18, tickfontsize=15, xscale=:log10,
                legendfontsize=15, guidefontsize=18, xlabel="A Glen", ylabel="Depth (m)",
                legend=true, margin= 10mm, size=(1200,1000), dpi=600)

"""
Solve the equations for parallel flow. 
Alought this is a very simplistic model, it help us to understand the 
impact of temperature in velocities

This is steady state. For something more realistic, solving Eq. 8.29 in Cuffey
would be a better idea. 
"""

function dz!(du, u, p, z)
    # Temperature at Depth
    T = Temperature(z)
    A = A_Glen(T)
    @show T, A
    du .= 2 .* A .* τb^n .* (1 .- z./H).^n
end

function dz₀!(du, u, p, z)
    A = A_Glen(T₀)
    du .= 2 .* A .* τb^n .* (1 .- z./H).^n
end

# # Solve ODE
u0 = [ub]
tspan = (0.0, H)

prob = ODEProblem(dz!, u0, tspan)
sol = solve(prob, Tsit5(), reltol = 1e-12, abstol = 1e-12, saveat=zs)
Us = only.(sol.u) * secs_in_year

prob₀ = ODEProblem(dz₀!, u0, tspan)
sol₀ = solve(prob₀, Tsit5(), reltol = 1e-12, abstol = 1e-12, saveat=zs)
Us₀ = only.(sol₀.u) * secs_in_year

plot_velocity = Plots.plot(Us, zs, label="Velocity (T dep)", lw=5, ms=3, msw=0.01)
Plots.plot!(Us₀, zs, label="Velocitity (T indep)", lw=5, ms=3, msw=0.01, ls=:dash)
Plots.plot!(fontfamily="Computer Modern", title="Velocity Profile", titlefontsize=18, tickfontsize=15,
                legendfontsize=15, guidefontsize=18, xlabel="Velocity (m/yr)", ylabel="Depth (m)",
                legend=true, margin= 10mm, size=(1200,1000), dpi=600)
# Plots.savefig(plot_T, "figures/temperature_velocity.pdf")

combo_plot = plot(plot_T, plot_A, plot_velocity, layout = (1, 3))
plot!(fontfamily="Computer Modern", size=(1600,1000))
Plots.savefig(combo_plot, "figures/temperature_velocity.pdf")