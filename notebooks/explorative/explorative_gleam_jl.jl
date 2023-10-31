#   Explore Gleam.jl
#   ==================

using DrWatson 
@quickactivate "diff_gleam"
using Plots
using ModelingToolkit
using DifferentialEquations
using DataInterpolations
# using Gleam  #First option, import all of Gleam
import Gleam.physics: calculate_λ, calculate_γ, evaporation_to_mm_per_day
import Gleam.physics: calculate_Δ, calculate_priestley_taylor

# Gleam.physics.calculate_lambda(3.0) #when using the first option!
calculate_λ(3.0)

#   Mini-test on float values

Tc = 20.0 #°C
α = 1.26 #classic low vegetation values
AE = 200. #W/m^2
λ = calculate_λ(Tc)
γ = calculate_γ(λ)
Δ = calculate_Δ(Tc)
Ep = calculate_priestley_taylor(AE, Δ, γ, α)

#   Mini-test on 1D array

incoming_AE = [150.0, 125.0, 100.0, 75.0, 75.0, 100.0, 125.0, 150.0, 175.0, 
200.0, 225.0, 250.0, 275.0, 300.0, 325.0, 350.0, 375.0, 400.0, 425.0, 450.0, 475.0]
air_temperature = [20.5, 19.0, 17.8, 16.5, 16.5, 17.8, 19.0, 20.5,
 22.0, 23.5, 25.0, 26.5, 28.0, 29.5, 31.0, 32.5, 34.0, 35.5, 37.0, 38.5, 40.0]

λ = calculate_λ.(air_temperature)
γ = calculate_γ.(λ)
Δ = calculate_Δ.(air_temperature)
Ep = calculate_priestley_taylor.(incoming_AE, Δ, γ, α)
plot(Ep, label = "λEₚ [W/m²]")

#   Now try for a 2D array

# Synthetic data for net incoming radiation (W/m^2)
incoming_AE = [
    150.2  145.5  140.3  135.7  130.8;
    125.6  120.0  115.2  110.9  105.3;
    100.8  95.6   90.4   85.1   80.5;
    75.7   70.2   65.4   60.9   55.3;
    50.1   45.5   40.3   35.7   30.9
]

# Synthetic data for air temperature (°C)
air_temperature = [
    20.6  19.8  18.7  17.9  16.8;
    22.3  21.5  20.4  19.6  18.5;
    24.1  23.3  22.2  21.4  20.3;
    25.7  24.9  23.8  23.0  21.9;
    27.4  26.6  25.5  24.7  23.6
]
λ = calculate_λ.(air_temperature)
γ = calculate_γ.(λ)
Δ = calculate_Δ.(air_temperature)
Ep = calculate_priestley_taylor.(incoming_AE, Δ, γ, α)
heatmap(Ep, title = "λEₚ [W/m²]")

#   First attempt at a interception module
#   ========================================
# 
#   Try to create with the ModellingToolkit.jl framework

# Time vector (hourly measurements)
time_days = collect(0:9)/24  # 0 to 9 hours

# Synthetic data for leaf area index (LAI)
lai = [2.5, 2.8, 3.1, 3.4, 3.7, 4.0, 4.3, 4.3, 4.3, 4.3]

# Synthetic data for precipitation intensity (mm/day)
precipitation_intensity = [6.2, 7.5, 5.8, 8.2, 6.5, 7.8, 5.5, 8.9, 7.2, 0.0];

#   Prepare following discrete values for use with differential equation solver,
#   https://discourse.julialang.org/t/interpolation-within-modelingtoolkit-framework/59432/6

# function lai_interpolate(t, t_vals, lai_vals)
#     interp_lai = LinearInterpolation(lai_vals, t_vals)
#     output = interp_lai(t)
# end
interp_lai = LinearInterpolation(lai, time_days, extrapolate = true)
interp_p = ConstantInterpolation(precipitation_intensity, time_days, dir = :right, extrapolate = true)#rigth piecewise
t_plot = collect(0:0.01:20)/24
plot(t_plot, interp_lai(t_plot), label = "LAI [-]", xlabel = "t[days]", color = :green)
scatter!(time_days, lai, label = "LAI [-]", xlabel = "t[days]", color = :green)
plot!(t_plot, interp_p(t_plot), label = "P [mm/day]", color = :blue)
scatter!(time_days, precipitation_intensity, label = "P [mm/day]", color = :blue)

plot_folder = projectdir("plots","Interception_experiment")
folder_function = plot_name -> projectdir("plots","Interception_experiment",plot_name)
if !isdir(plot_folder)
    mkdir(plot_folder)
end
savefig(folder_function("forcings.png"))

# function intercpetion_model()
# #place mtk model here later
# end

function mtk_interception(Ep_use = false;name)
    @parameters q, b, Sₜ, Sₗ, Ec
    @variables t, Cᵥ(t), P(t), LAI(t), Sᵥ(t), D(t), d(t), I(t)
    δ = Differential(t)

    eqs = [
        P ~ interp_p(t)
        LAI ~ interp_lai(t)
        Sᵥ ~ Sₜ + LAI* Sₗ
        D ~ ifelse(Cᵥ > Sᵥ, b*(Cᵥ - Sᵥ),0.0)
        d ~ ifelse(Cᵥ > Sᵥ, 0.0, q*Cᵥ)
        I ~ ifelse(Ep_use,
                ifelse(Cᵥ > 0, Ec*Cᵥ/Sᵥ, 0),
                ifelse(Cᵥ > 0, Ec*Cᵥ/Sᵥ, 0),
            )
        δ(Cᵥ) ~ P - I - D - d
    ]
    return ODESystem(eqs; name)
end
@named test = mtk_interception()

test_simp = complete(structural_simplify(test))

u0 = [test_simp.Cᵥ => 0.0]
t_span = (0.0, 20.0/24)
p = [
    test_simp.q => 2.4, #d^-1 = 0.3h^-1
    test_simp.b => 500, #d^-1
    test_simp.Ec => 0.32*24, #mm/d
    test_simp.Sₜ => 0.09, #mm
    test_simp.Sₗ => 0.294, #mm
]
prob = ODEProblem(test_simp, u0, t_span, p)
sol = solve(prob) #Tsit5(), saveat = collect(0:20)/24)#, Tsit5(), reltol = 1e-8, abstol = 1e-8)
plot(sol, idxs =[test_simp.Cᵥ, test_simp.Sᵥ],  xlabel = "t[days]", ylabel = "[mm]")
#add the discret points
p1 = scatter!(sol.t,sol[test_simp.Cᵥ], label = "Cᵥ(t)", color = :blue)

sol.t

sol.u

p2 = plot(sol, idxs = [test_simp.d, test_simp.D, test_simp.I], ylabel = "[mm/d]", xlabel = "t[days]", show =true)
scatter!(sol.t, sol[test_simp.d], ylabel = "[mm/d]", label = "d(t)", color = :blue)
scatter!(sol.t, sol[test_simp.D], label = "D(t)", color = :red)
scatter!(sol.t, sol[test_simp.I], label = "I(t)", color = :green)

p_all = plot(p1,p2, size = (800,500))
savefig(folder_function("ouptut.png"))
p_all

#   Test using Ep instead of Ec
#   –––––––––––––––––––––––––––––

incoming_AE = [150.0, 125.0, 100.0, 75.0, 75.0, 100.0, 125.0, 150.0, 175.0, 
200.0]
air_temperature = [20.5, 19.0, 17.8, 16.5, 16.5, 17.8, 19.0, 20.5,
 22.0, 23.5]
interp_ae = LinearInterpolation(incoming_AE, time_days, extrapolate = true)
interp_ta = LinearInterpolation(air_temperature, time_days, extrapolate = true);

#   ALWAYS register your functions to be symbolic OUTSIDE of functions (see
#   here:
#   https://discourse.julialang.org/t/how-can-i-use-register-symbolic-inside-of-a-function/101734/5)
#   or use (eval(:(@register_symbolic ...)))

@variables t, Tₐ(t), λ(t), AE(t), Δ(t), γ(t), α(t), Ep_wm2(t)
@register_symbolic calculate_Δ(Tₐ)
@register_symbolic calculate_λ(Tₐ)
@register_symbolic calculate_γ(λ)
@register_symbolic calculate_priestley_taylor(AE, Δ, γ, α)
@register_symbolic evaporation_to_mm_per_day(Ep_wm2, λ)

methods(calculate_Δ)

function mtk_interception_Ep(;name)
    @parameters q, b, Sₜ, Sₗ, α
    @variables begin 
        t, Cᵥ(t), P(t), AE(t), Tₐ(t), LAI(t),
        Ep(t), Sᵥ(t), D(t), d(t), I(t), Δ(t),
        γ(t),λ(t)
    end
    δ = Differential(t)

    eqs = [
        P ~ interp_p(t)
        AE ~ interp_ae(t)
        Tₐ ~ interp_ta(t)
        LAI ~ interp_lai(t)
        Δ ~ calculate_Δ(Tₐ)
        λ ~ calculate_λ(Tₐ)
        γ ~ calculate_γ(λ)
        Ep_wm2 ~ calculate_priestley_taylor(AE, Δ, γ, α)
        Ep ~ evaporation_to_mm_per_day(Ep_wm2, λ)
        Sᵥ ~ Sₜ + LAI* Sₗ
        D ~ ifelse(Cᵥ > Sᵥ, b*(Cᵥ - Sᵥ),0.0)
        d ~ ifelse(Cᵥ > Sᵥ, 0.0, q*Cᵥ)
        I ~ ifelse(Cᵥ > 0, Ep*Cᵥ/Sᵥ, 0)   
        δ(Cᵥ) ~ P - I - D - d
    ]
    return ODESystem(eqs; name)
end
@named test_ep = mtk_interception_Ep()

test_ep_simp = complete(structural_simplify(test_ep))

u0 = [test_ep_simp.Cᵥ => 0.0]
p = [
    test_ep_simp.q => 2.4, #d^-1 = 0.3h^-1
    test_ep_simp.b => 500, #d^-1
    test_ep_simp.Sₜ => 0.09, #mm
    test_ep_simp.Sₗ => 0.294, #mm
    test_ep_simp.α => 1.26 #[-]
]

prob_ep = ODEProblem(test_ep_simp, u0, t_span, p)
sol_ep = solve(prob_ep) #Tsit5(), saveat = collect(0:20)/24)#, Tsit5(), reltol = 1e-8, abstol = 1e-8)
plot(sol_ep, idxs =[test_ep_simp.Cᵥ, test_ep_simp.Sᵥ],  xlabel = "t[days]", ylabel = "[mm]")
#add the discret points
p1 = scatter!(sol_ep.t,sol_ep[test_simp.Cᵥ], label = "Cᵥ(t)", color = :blue)

plot(sol_ep, idxs = [test_ep_simp.Ep, test_ep_simp.I, test_ep_simp.d, test_ep_simp.D],
 ylabel = "[mm/day]", xlabel = "t[days]")

plot(sol_ep, idxs = [test_ep_simp.P, test_ep_simp.LAI],
 ylabel = "[mm/day]", xlabel = "t[days]")

#   Ep without the modellingtoolkit framework
#   –––––––––––––––––––––––––––––––––––––––––––

d_vector = []
function rutter_ep!(u, p, t)
    Cᵥ = u
    q, b, Sₜ, Sₗ, α, P, AE, Tₐ, LAI = p
    Δ, λ = calculate_Δ(Tₐ(t)), calculate_λ(Tₐ(t))
    γ = calculate_γ(λ)
    Ep = evaporation_to_mm_per_day(
        calculate_priestley_taylor(AE(t), Δ, γ, α), λ
    )
    Sᵥ = Sₜ + LAI(t)*Sₗ
    D = ifelse(Cᵥ > Sᵥ, b*(Cᵥ - Sᵥ), 0.0)
    d = ifelse(Cᵥ > Sᵥ, 0.0, q*Cᵥ)
    push!(d_vector, d)
    I = ifelse(Cᵥ > 0.0, Ep*Cᵥ/Sᵥ, 0.0)
    dCᵥ =  P(t) - I - D - d 
    return dCᵥ
end
# f(u,p,t) form instead of f(du, u, p, t) form used here

u₀ = 0.0
p = (
    2.4, #q: d^-1
    500.0, #b: d^-1
    0.09, #S_t: mm
    0.294, #S_l: mm
    1.25, #alpha: -
    t -> interp_p(t), #precipitation
    t -> interp_ae(t), #Available energy
    t -> interp_ta(t), #air temperature
    t -> interp_lai(t) #LAI
)
prob_diff_eq = ODEProblem(rutter_ep!, u₀, t_span, p)
sol_diff_eq = solve(prob_diff_eq)
plot(sol_diff_eq, label = "Cᵥ(t)")

# modelingtoolkitize(prob_diff_eq) #does not work

solve(prob_diff_eq)

#   DISADVANTAGE of this approach: you cannot easily access the fluxes

using NBInclude
nbexport("explorative_gleam_jl.jl", "explorative_gleam_jl.ipynb")

plot(d_vector)

#   End conclusion: modellingtoolkit framework preferable, as it allows to
#   easily track all the the fluxes. Deemded more important than the
#   disadvantage of translating the functions to symbolci

#   An all-encompassing function
#   ––––––––––––––––––––––––––––––

forcings = Dict(
    "AE" => incoming_AE,
    "Tₐ" => air_temperature,
    "LAI" => lai,
    "P" => precipitation_intensity
)

#Idea: have a dictionary of dataframes as input
#Each dataframe can have different time resolutions, BUT this does not matter
#since we will interpolate each seperately 
function interpolate_forcings(forcings::Dict)
    forcings_vars = keys(forcings)
    interpol_dict = Dict()
    for var in forcings_vars
        if var == "P"
            interpol_dict[var] = ConstantInterpolation(
                forcings[var],
            )
        else
            interpol_dict[var] = LinearInterpolation()
    end

end
function Interception(forcings::Dict)


end

for i in keys(forcings)
    print(i*"\n")
end

using DataFrames