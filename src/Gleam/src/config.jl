# Priestley and Taylor coefficients (alpha) for different land cover
# types.
#
# alpha is an empirically derived coefficent used to estimate the
# potential evaporation, which has an aerodynamic and a radiative
# component, from just the radiative component. Given alpha = 1.26 for
# example, the aerodynamic component is estimated to be 26% of the
# radiative one.
#
# Latest values here date from Update of Akash 2 year according
# Note here that:
# -by setting α to 1 for condensation, you no longer say that there is
# only a aerodynamic component remaining
# -For low vegetation, 1 deviates from the classic 1.26 for wet grassland

const α = Dict('T' => 0.90,  # tall vegetation
         'H' => 1.00,  # herbaceous (aka low) vegetation
         'B' => 1.26,  # bare soil
         'W' => 1.26,  # open water
         'S' => 1.26,  # snow
         'C'=> 1.00)  # condensation on any land cover

# Fraction of interception loss needed to correct transpiration (Gash
# and Steward, 1977). From the GLEAM v3 paper by Martens et al. (2017):
# "In GLEAM, canopy rainfall interception is calculated independently.
# As a consequence of this separate estimation, the transpiration needs
# to be corrected by a fraction (beta) of the interception loss to avoid
# the double counting of evaporation for those hours with wet canopy."
const β = 0.07

# The available energy (AE) for evaporation is equal to the net
# radiation (Rn) minus the ground heat flux (G). Because G is assumed to
# be a fixed fraction of Rn, also AE is a fraction (fAE) of Rn. For
# negative Rn, G is zero and AE equals Rn.
const fAE = Dict('T'=> 0.90,  # tall vegetation
       'H'=> 0.80,  # herbaceous (aka low) vegetation
       'B'=> 0.65,  # bare soil
       'W'=> 1.00,  # open water
       'S'=> 0.80)  # snow

# Soil layer depths
const layer_depths = [100., 900., 1500.]  # mm