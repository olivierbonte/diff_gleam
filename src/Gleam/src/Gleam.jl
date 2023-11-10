module Gleam
#This is the top level module. Add all the files that are included
#in the model here wit the include() command
#For each file we define a submodule. This keeps the code very 'Python-like'
# e.g. `import Gleam.phyiscs: calculate_lambda`
#Alternatively, you can use: `using Gleam` and then code
#´Gleam.phyiscs.calculate_lambda(example_value)` 

module config
include("config.jl")
end

module constants
include("constants.jl")
end

module evaporation
include("evaporation.jl")

module physics
include("physics.jl")
end
greet() = print("Hello World!")

end # module Gleam
