# diff_gleam

This code base is using the [Julia Language](https://julialang.org/) and
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
to make a reproducible scientific project named
> diff_gleam

It is authored by Olivier Bonte.

To (locally) reproduce this project, do the following:

0. Download this code base. Notice that raw data are typically not included in the
   git-history and may need to be downloaded independently. This is done easily with git:
   ```
   git clone https://github.com/olivierbonte/diff_gleam
   ```
1. Open a Julia console and, after navigating into the diff_gleam folder. In the command line interface (CLI) this is:
   ```
   cd diff_gleam
   julia
   
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> using DrWatson
   julia> @quickactivate "diff_gleam"
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

diff_gleam depends on some python packages, which are called from Julia using [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) or are run from Python. Therefore, one first needs to set up a Python environment. For this purpose one can use conda, but [(micro)mamba](https://mamba.readthhttps//mamba.readthedocs.io/en/latest/index.htmledocs.io/en/latest/index.html) is recommended. With mamba, use following commands in the command line interface:
```
mamba env create -f environment.yml
mamba activate diff_gleam_python
```
After activating the environment, it should be passed to Pycall.jl as follows:

```julia
julia # start Julia session

julia> using DrWatson
julia> @quickactivate "diff_gleam"
julia> all_envs = read(`which python`, String)
julia> ENV["PYTHON"] = split(all_envs, '\n')[1][1:end-1] # select first and trim backspace
julia> import Pkg; Pkg.build("PyCall")
julia> exit()

# Now you can run your code using in a new Julia session; e.g.:
julia
julia> using DrWatson
julia> @quickactivate "diff_gleam"
julia> using PyCall
julia> Pycall.python
```
Note that `which python` only works on MacOS/Linux, for Windows systems use `where python`. If the last command (`Pycall.python`) returns the path of the `diff_gleam_ptyhon.exe` conda environment, then the building of PyCall has been successful. 

You may notice that most scripts start with the commands: 
```julia
using DrWatson
@quickactivate "diff_gleam"
```
which auto-activate the project and enable local path handling from DrWatson.
