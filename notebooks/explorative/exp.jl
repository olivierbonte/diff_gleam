using DrWatson
@quickactivate "diff_gleam"
using ModelingToolkit, Lux, Random

#based on this example

tspan = (0.0f0,8.0f0)
rng = Random.default_rng()
    ann = Lux.Chain(
    Lux.Dense(1,6),
    Lux.Dense(6,6,tanh),
    Lux.Dense(6,1)
)
θ, st = Lux.setup(rng, ann) #initialise random weights!

#mtk
function an_for_sym(x,p)
    return ann(x, p, st)[1]
end
@variables t, x(t), xx(t)
@parameters p
@register_symbolic an_for_sym(x,p)
D = Differential(t)
eqs = [
    D(x) ~ xx,
    D(xx) ~ an_for_sym(x,p)
]
@named sys = ODESystem(eqs,t,[x,xx],p)
