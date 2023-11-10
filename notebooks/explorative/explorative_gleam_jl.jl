#   Explore Gleam.jl
#   ==================

using DrWatson 
@quickactivate "diff_gleam"
using Plots
using ModelingToolkit
using DifferentialEquations
using DataInterpolations
using DataFrames
# using Gleam  #First option, import all of Gleam
import Gleam.physics: calculate_λ, calculate_γ, evaporation_to_mm_per_day
import Gleam.physics: calculate_Δ, calculate_priestley_taylor
import Gleam.evaporation: calculate_EP

# Structs defining the GLEAM model 
# ================================

mutable struct parameters
    q::Float64
    b::Float64
    S_t::Float64
    S_l::Float64
    α::Float64
end

mutable struct forcings
    P::DataFrame
    AE::DataFrame
    Tₐ::DataFrame
    lai::DataFrame
end

mutable struct forcings_itp
    P
    AE
    Tₐ
    lai
    forcings_itp() = new()
end

mutable struct states 
    Cᵥ::AbstractArray
    Sᵥ::AbstractArray
end

mutable struct gleam_struct
    parameters::parameters
    forcings::forcings
    forcings_itp::forcings_itp
    states::states
end

# Example datasets 
# ================

p_struct = parameters(
    2.4, #q: d^-1
    500.0, #b: d^-1
    0.09, #S_t: mm
    0.294, #S_l: mm
    1.25, #alpha: -
)

# Time vector (hourly measurements)
time_days = collect(0:9)/24  # 0 to 9 hours

# Synthetic data for leaf area index (LAI)
lai = [2.5, 2.8, 3.1, 3.4, 3.7, 4.0, 4.3, 4.3, 4.3, 4.3]
# Synthetic data for precipitation intensity (mm/day)
precipitation_intensity = [6.2, 7.5, 5.8, 8.2, 6.5, 7.8, 5.5, 8.9, 7.2, 0.0];
incoming_AE = [150.0, 125.0, 100.0, 75.0, 75.0, 100.0, 125.0, 150.0, 175.0, 
200.0]
air_temperature = [20.5, 19.0, 17.8, 16.5, 16.5, 17.8, 19.0, 20.5,
 22.0, 23.5]

 #Make DataFrames of this
lai_pd = DataFrame(Dict(
    "t" => time_days,
    "val" => air_temperature
))
p_pd = DataFrame(Dict(
    "t" => time_days,
    "val" => precipitation_intensity
))
AE_pd = DataFrame(Dict(
    "t" => time_days,
    "val" => incoming_AE
))
Ta_pd = DataFrame(Dict(
    "t" => time_days,
    "val" => air_temperature
))


 forcing_struct = forcings(
    p_pd, AE_pd, Ta_pd, lai_pd
 )

 states_struct = states(
    Float64[], Float64[] #empty initialisation-
 )

 gleam_str = gleam_struct(
    p_struct,
    forcing_struct,
    forcings_itp(),
    states_struct
 )

# Define first function on the GLEAM struct
# =========================================

function interpolate_forcings!(gleam::gleam_struct)
    forcing_fields = fieldnames(typeof(gleam.forcings))
    for forcing in forcing_fields
        if forcing == :P
            setproperty!(
                gleam.forcings_itp, forcing,
                ConstantInterpolation(
                    getproperty(gleam.forcings,forcing).val,
                    getproperty(gleam.forcings,forcing).t,
                    dir = :right, extrapolate = true
                )
            )
        else
            setproperty!(
                gleam.forcings_itp, forcing,
                LinearInterpolation(
                    getproperty(gleam.forcings,forcing).val,
                    getproperty(gleam.forcings,forcing).t,
                    extrapolate = true                    
                )
            )
        end
    end
 end

 interpolate_forcings!(gleam_str)

function interception_fluxes(Cᵥ::AbstractFloat,Sᵥ::AbstractFloat, b::AbstractFloat, q::AbstractFloat,
    Ep::AbstractFloat)
    D = ifelse(Cᵥ > Sᵥ, b*(Cᵥ - Sᵥ), 0.0)
    d = ifelse(Cᵥ > Sᵥ, 0.0, q*Cᵥ)
    I = ifelse(Cᵥ > 0.0, Ep*Cᵥ/Sᵥ, 0.0) #TO BE ADPATED TO SIGMOID
    return D,d,I
end

function storage_capacity!(gleam_str::gleam_struct) 
    gleam_str.states.Sᵥ = Sₜ + gleam_str.forcings.lai*Sₗ
end

function rutter_ode!(dCᵥ, u, p, t)
    
end

function calculate_interception_fluxes!(gleam_str::gleam_str)

end



