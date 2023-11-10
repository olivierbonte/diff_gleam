using ModelingToolkit, Lux, Random
using DifferentialEquations, Plots

################# based on this example #################

tspan = (0.0f0,8.0f0)
rng = Random.default_rng()

ann = Lux.Chain(
    Lux.Dense(1,6),
    Lux.Dense(6,6,tanh),
    Lux.Dense(6,1)
)

random_nn_params, states = Lux.setup(rng, ann) #initialise random weights!

# check out how the ann function works
ann([1], random_nn_params, states) # function expects vector of length 1 as input and returns a tuple containing a vector containing the output
ann([1], random_nn_params, states)[1][1] # output number

dump(random_nn_params) # what's actually in here?

for field in fieldnames(typeof(random_nn_params)) # just weights and biases in a nested NamedTuple
    println(field, ": ", random_nn_params[field])
    println("Number of parameters: ", length(random_nn_params[field][:weight]), " + ", length(random_nn_params[field][:bias]), "\n")
end

# get total amount of parameters
num_params = sum([length(random_nn_params[field][:weight]) + length(random_nn_params[field][:bias]) for field in fieldnames(typeof(random_nn_params))])


################# simple example mimicing the ann #################

function simplefunc(x, p)
    out1 = [x]*reshape(p[1:3], 1, 3) + reshape(p[4:6], 1, 3) # 1 => 3 layer
    out2 = out1*reshape(p[7:15], 3, 3) + reshape(p[16:18], 1, 3) # 3 => 3 layer
    out3 = out2*reshape(p[19:21], 3, 1) + reshape(p[22:22], 1, 1) # 3 => 1 layer
    return out3[1]
end

test_p = collect(1:22)
simplefunc(1, test_p)

@variables t, x(t), xx(t)
@parameters simple_params[1:22]
@register_symbolic simplefunc(x, p)

D = Differential(t)
eqs = [
    D(x) ~ xx,
    D(xx) ~ simplefunc(x, simple_params)
]
@named sys = ODESystem(eqs, t, [x, xx], simple_params)
u0 = [x => 1.0, xx => 0.0]
t_span = (0.0, 10.0)
param_values = fill(1.0, 22)

prob = ODEProblem(sys, u0, t_span, param_values)
sol = solve(prob)
plot(sol)

################# real NN: try 1 #################

# start defining the system 

## symbolic nn function first
function an_for_sym(x, p)
    # define parameters for nn based as the expected NamedTuple based on vector p 
    luxified_nn_params = (; # NamedTuples can be defined using (; x1 = a1, x2 = a2, ...)
    layer_1 = (; weight = reshape(p[1:6], 6, 1), bias = reshape(p[7:12], 6, 1)),
    layer_2 = (; weight = reshape(p[13:48], 6, 6), bias = reshape(p[49:54], 6, 1)),
    layer_3 = (; weight = reshape(p[55:60], 1, 6), bias = reshape(p[61:61], 1, 1)),
    )
    return ann([x], luxified_nn_params, states)[1][1]
end
@register_symbolic an_for_sym(x, p)

## parameters, variables and the equations
@variables t, x(t), xx(t)
@parameters nn_params[1:num_params] # define as many parameters as required for ann
D = Differential(t)

eqs = [
    D(x) ~ xx,
    D(xx) ~ an_for_sym(x, nn_params)
]

## system definition
@named sys = ODESystem(eqs, t, [x, xx], nn_params) 
    # something weird is happening in the `isvariable` function
    # should return false if x is not a Symbolic yet it continues to the last line and invokes `hasmetadata`

### mess with the source code a little bit, no way this goes wrong
import .SymbolicUtils.hasmetadata

function hasmetadata(s::Base.ReshapedArray, ctx)
    return false # a hacky solution but it works!
end

@named sys = ODESystem(eqs, t, [x, xx], nn_params) # there we go

u0 = [x => 1.0, xx => 0.0]
t_span = (0.0, 10.0)
params = fill(1.0, 61)

prob = ODEProblem(sys, u0, t_span, params)
sol = solve(prob) # well, that's weird

################# real NN: try 2 #################
# maybe if we defined the nn parameters in the correct shape beforehand we won't get that weird error?

@parameters l1_w[1:6, 1], l1_b[1:6, 1], l2_w[1:6, 1:6], l2_b[1:6, 1], l3_w[1, 1:6], l3_b[1:1, 1] 
    # l1_w = layer 1 weights, l1_b = layer 2 bias, and so on

function an_for_sym2(x, p)
    l1_w, l1_b, l2_w, l2_b, l3_w, l3_b = p
    new_nn_params = (; # no reshaping required anymore
    layer_1 = (; weight = l1_w, bias = l1_b),
    layer_2 = (; weight = l2_w, bias = l2_b),
    layer_3 = (; weight = l3_w, bias = l3_b),
    )
    return ann([x], new_nn_params, states)[1][1]
end

@register_symbolic an_for_sym2(x, p)

eqs = [
    D(x) ~ xx,
    D(xx) ~ an_for_sym2(x, [l1_w, l1_b, l2_w, l2_b, l3_w, l3_b])
] # now there's a weird error involved in how Symbolics defines the `axes` of a variable

# oh well
import .Symbolics.axes

function axes(array::Union{Symbolics.Arr, SymbolicUtils.BasicSymbolic})
    return map(Base.OneTo, size(array))
end

function axes(array::Union{Symbolics.Arr, SymbolicUtils.BasicSymbolic}, idx)
    return idx > ndims(array) ? Base.OneTo(1) : Base.OneTo(size(array)[idx])
end

eqs = [
    D(x) ~ xx,
    D(xx) ~ an_for_sym2(x, [l1_w, l1_b, l2_w, l2_b, l3_w, l3_b])
] # et voila

@named sys = ODESystem(eqs, t, [x, xx], [l1_w..., l1_b..., l2_w..., l2_b..., l3_w..., l3_b...]) 
    # make sure to do the splatting (`...`) or you input an array of arrays as the parameter array
    # which MTK can't deal with. single-dimensional arrays only.

u0 = [x => 1.0, xx => 0.0]
t_span = (0.0, 10.0)
param_values = fill(1.0, 61)

prob = ODEProblem(sys, u0, t_span, param_values)
sol = solve(prob) # well, it's a different error now at least