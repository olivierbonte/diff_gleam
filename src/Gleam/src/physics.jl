import Gleam.constants: 
    zero_celsius_in_kelvin,
    specific_heat_air,
    air_pressure_at_sea_level,
    specific_gravity_water_vapor,
    seconds_per_day,
    millimeters_per_meter,
    water_density

"""
    celsius_to_kelvin(Tₐ::AbstractFloat)

Convert temperature from degress Celsius to Kelvin 
"""
function celsius_to_kelvin(Tₐ::AbstractFloat)
    return zero_celsius_in_kelvin + Tₐ
end


"""
    evaporation_to_mm_per_day(E::AbstractFloat, λ::AbstractFloat)

Converts evaporations from W/m^2 to mm/day

# Arguments
- `E::AbstractFloat`: Evaporation [W/m^2]
- `λ::AbstractFloat`: latent heat for water vaporaisation [J/kg]

# Returns
- `::AbstractFloat`: Evaporation [mm/day]

"""
function evaporation_to_mm_per_day(E::AbstractFloat, λ::AbstractFloat)
    return (seconds_per_day*millimeters_per_meter*E)/
            (λ * water_density)
end


""" 
    calculate_lambda(Tₐ::AbstractFloat)

Calculate the latent heat of vaporization of water according to
Henderson-Sellers (1984), equation 8.

# Arguments
- `Tₐ::AbstractFloat`: Air temperature [°C]

# Returns
- `λ::AbstractFloat`: Latent heat of vaporization of water [J/kg]
    
"""
function calculate_λ(Tₐ::AbstractFloat)
    Tₐ = celsius_to_kelvin(Tₐ)
    b₀, b₁ = 1.91846e6, -33.91  # empirical coefficients
    λ = b₀ * (Tₐ/(Tₐ + b₁))^2
    return λ
end
    
"""
    calculate_gamma(λ::AbstractFloat)

Calculate the psychrometric constant of the air according to
Brunt (1952).

# Arguments
- `λ:AbstractFloat`: latent heat of vaporaisation [J/kg]

# Returns
- `γ::AbstractFloat`: 
"""
function calculate_γ(λ::AbstractFloat)
    γ = (specific_heat_air*air_pressure_at_sea_level)/
    (specific_gravity_water_vapor*λ)
    return γ
end

"""
    calculate_Δ(Tₐ::AbstractFloat)

Calculate the derivative of the saturated water vapour pressure vs.
temperature relationship according to Shuttleworth (1993; 
in Handbook of Hydrology, edited by Maidment), equation 4.2.3.

# Arguments
- `Tₐ::AbstractFloat`: Air temperature [°C]

# Returns
- `Δ::AbstractFloat`: derivative of the saturated water vapour pressure vs. 
    temperature relationship [Pa/°C]
"""
function calculate_Δ(Tₐ::AbstractFloat)
    b0, b1, b2 = 0.6108, 17.27, 237.3  # empirical coefficients
    sat_vap_p = 1e3 *b0 *exp((b1 * Tₐ)/(b2 + Tₐ))
    Δ = b1 * b2 * sat_vap_p/(b2 + Tₐ)^2
    return Δ
end

"""
    calculate_priestlye_taylor(AE::AbstractFloat, Δ::AbstractFloat, 
            γ::AbstractFloat, α:AbstractFloat)

Calculate potential evaporation according to Priestley and Taylor (1972).

# Arguments
- `AE::AbstractFloat`: Available energy [W/m^2]
- `Δ: AbstractFloat`: Slope of the saturated water vapour pressure to 
        temperature curve [Pa/°C]
- `γ::AbstractFloat`: Psychrometric constant of the air [Pa/°C]
- `α::AbstractFloat`: Priestly and Taylor constant [-]

# Returns
- `λEₚ::AbstractFloat`: Potential evaporation [W/m^2]

"""
function calculate_priestley_taylor(AE::AbstractFloat, Δ::AbstractFloat, 
        γ::AbstractFloat, α::AbstractFloat)
        λEₚ = α * Δ * AE/(Δ + γ)
        return λEₚ
end