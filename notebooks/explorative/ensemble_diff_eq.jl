using DrWatson
@quickactivate "diff_gleam"
using DifferentialEquations
using Logging: global_logger
using TerminalLoggers: TerminalLogger
# using Pkg
# Pkg.add("BenchmarkTools")
using BenchmarkTools
global_logger(TerminalLogger())

# https://docs.sciml.ai/DiffEqDocs/stable/features/progress_bar/

f_matrix(u,p,t) = 1.01 .* u
size = 100
u0_matrix = rand(size,size) #went to 10 000 x 10 000
tspan = (0.0, 2.0)
matrix_problem = ODEProblem(f_matrix, u0_matrix, tspan)
sol_matrix = solve(matrix_problem, DP5(), progress = true)

@btime sol_matrix_benchmark = solve(matrix_problem, DP5())

#Alternative way of solving
# https://docs.sciml.ai/DiffEqDocs/stable/features/ensemble/

scalar_problem = ODEProblem(f_matrix, 0.0, tspan)
nr_trajectories = size * size
function prob_func(prob, i , repeat)
    remake(prob, u0 = u0_matrix[i])
end
ensemble_prob = EnsembleProblem(scalar_problem, prob_func = prob_func)
@btime ensmeble_sol = solve(ensemble_prob, Tsit5(), EnsembleThreads(),
trajectories = nr_trajectories)

#trying to parallelise this FAILS
# using Distributed 
# addprocs()
# @everywhere using DifferentialEquations

# @everywhere u0_matrix_para = rand(size, size)
# @everywhere function prob_func_para(prob, i , repeat)
#     remake(prob, u0 = u0_matrix_para[i])
# end

# ensemble_prob_para = EnsembleProblem(scalar_problem, prob_func = prob_func_para)
# @btime ensmeble_sol_para = solve(ensemble_prob_para, Tsit5(), EnsembleDistributed(),
# trajectories = nr_trajectories)

