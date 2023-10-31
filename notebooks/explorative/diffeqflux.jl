#   DiffEqFlux
#   ≡≡≡≡≡≡≡≡≡≡≡≡
# 
#   Foucs = Universal Differential Equations SciMLSensitiviy.jl = underlyin, see
#   https://docs.sciml.ai/SciMLSensitivity/stable/getting_started/
# 
#   Lux.jl neural network are preferred for technical reasons:
#   https://docs.sciml.ai/DiffEqFlux/stable/#Flux.jl-vs-Lux.jl
# 
#     •  https://www.youtube.com/watch?v=5jF-cDNSkg&abchannel=TheJuliaProgrammingLanguage
#        • EXPLICIT parameterisation! specifyin the trainable and
#        non-trainable parts of the model. So give explicitly to
#        Zygote what you want to differentiate!
#        • Similar to Flux for backend!
# 
#   Tutorial on Neural ODE:
#   https://docs.sciml.ai/DiffEqFlux/stable/examples/neural_ode/

using DrWatson 
@quickactivate "diff_gleam"
using ComponentArrays, Lux, DiffEqFlux, DifferentialEquations
using Optimization #, OptimizationOptimJL, OptimizationFlux,
using Random, Plots

rng = Random.default_rng() #Return the default global random number generator (RNG).
u0 = Float32[2.0; 0.0]
datasize = 30
tspan = (0.0f0, 1.5f0)
tsteps = range(tspan[1],tspan[2], length = datasize)

#so the ODE we want to approximate
function trueODEfunc(du, u, p, t)
    true_A = [-0.1 2.0; -2.0 -0.1]
    du .= ((u.^3)'true_A)' #' denotes the transpose
end
prob_trueode = ODEProblem(trueODEfunc, u0, tspan)
sol_trueode = solve(prob_trueode, Tsit5(), saveat = tsteps)
plot(sol_trueode) #plot recipe for this solution object

#   So above, we see the real function we want to approximate using the
#   NeuralODE!

ode_data = Array(sol_trueode) #time and solution as matrix!

dudt2 = Lux.Chain(
    x -> x.^3, #include this as prior knowledge!
    Lux.Dense(2,50,tanh),
    Lux.Dense(50,2)
)

p, st = Lux.setup(rng, dudt2) #initialise random weights!
#p = parmaeter, st = state varaibals

prob_neuralode = NeuralODE(dudt2, tspan, Tsit5(), saveat = tsteps)
#default is the adjoint method!

function predict_neuralode(p)
    Array(prob_neuralode(u0, p, st)[1])
end

function loss_neuralode(p)
    pred = predict_neuralode(p)
    loss = sum(abs2,ode_data .- pred) #abs2 = square ob the absolute value, applied on each element
    return loss, pred
end

#   To explain the code above!

test = prob_neuralode(u0,p,st) #so this is FORWARD mode!

Array(test[1])

loss_neuralode(p)[1] #the current loss

callback = function(p, l, pred; doplot = true)
    println(l)
    # plot current prediction against data
    if doplot
        plt = scatter(tsteps, ode_data[1,:], label = "data")
        scatter!(plt, tsteps, pred[1,:], label = "prediction")
        display(plot(plt))
    end
    return false
end

pinit = ComponentArray(p) #useful for problems with mutable arrays
callback(pinit, loss_neuralode(pinit)...) #3 dots to expand

#   First ADAM is used, then LBFGS is used

#ADtype
adtype = Optimization.AutoZygote() #for Reversemode AD

#x = the parameters = the old 'p' = what we want to change
#p = the hyperparameters of the opitmization
loss_ft_for_opt = (x,p) -> loss_neuralode(x) #obliged form
optf = Optimization.OptimizationFunction(loss_ft_for_opt, adtype)
optprob = Optimization.OptimizationProblem(optf, pinit)

using OptimizationFlux #for using Adam
#the first training with Adam
result_neuralode = Optimization.solve(
    optprob,
    Adam(0.05), #0.05 = the learning rate
    callback = callback,
    maxiters = 300
)

#   Retrain with LBFGS

using OptimizationOptimJL
optprob2 = remake(optprob, u0 = result_neuralode.u)
results_neuralode2 = Optimization.solve(
    optprob2,
    Optim.BFGS(),
    callback = callback,
    allow_f_increases =false #stop near minimum
)

callback(results_neuralode2.u, loss_neuralode(results_neuralode2.u)...; doplot=true)