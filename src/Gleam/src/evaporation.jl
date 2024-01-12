import Gleam.physics:
    calculate_Δ, calculate_γ, calculate_λ,
    calculate_priestley_taylor,
    evaporation_to_mm_per_day



"""
    calculate_EP(Tₐ::AbstractFloat, AE::AbstractFloat,
    α::AbstractFloat)


Master function to calculate potential evaporation in GLEAM.

# Arguments:
- `Tₐ : AbstractFloat` Air temperature [°C]
- `AE : AbstractFloat` Available energy [W/m2]
- `α : AbstractFloat` Priestley and Taylor constant [-]

# Returns
- `Eₚ : AbstractFloat` Potential evaporation [mm/day]

"""
function calculate_EP(Tₐ::AbstractFloat, AE::AbstractFloat,
    α::AbstractFloat)
    Δ, λ = calculate_Δ(Tₐ), calculate_λ(Tₐ)
    γ = calculate_gamma(λ)
    Ep_wm2 = calculate_priestley_taylor(AE, Δ, γ, α)
    Eₚ = evaporation_to_mm_per_day(Ep_wm2, λ)
    return Eₚ
end