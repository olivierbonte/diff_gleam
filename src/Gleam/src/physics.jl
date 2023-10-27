import Gleam.constants: 
    zero_celsius_in_kelvin

"""
    celsius_to_kelvin(Tₐ::AbstractFloat)

Convert temperature from degress Celsius to Kelvin 
"""
function celsius_to_kelvin(Tₐ::AbstractFloat)
    return zero_celsius_in_kelvin + Tₐ
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
function calculate_lambda(Tₐ::AbstractFloat)
    Tₐ = celsius_to_kelvin(Tₐ)
    b₀, b₁ = 1.91846e6, -33.91  # empirical coefficients
    return b₀ * (Tₐ/(Tₐ + b₁))^2
end
    