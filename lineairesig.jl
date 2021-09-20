using DataFrames
# using StatsBase
using Statistics
# using DelimitedFiles
# using SASLib
# using RData
using GLM
using Lasso
using Distributions
using CSV

# https://stackoverflow.com/questions/53345724/how-to-use-julia-to-compute-the-pearson-correlation-coefficient-with-p-value
# cortest(x,y) =
#     if length(x) == length(y)
#         2 * ccdf(Normal(), atanh(abs(cor(x, y))) * sqrt(length(x) - 3))
#     else
#         error("x and y have different lengths")
#     end
cortest(x) = 2 * ccdf.(Normal(), atanh.(abs.(cor(x))) * sqrt(size(x)[1] - 3))

uscrime =
  CSV.read("Donnees\\USCrime.html", skipto = 39, footerskip = 1, header = 38)

# uscrime2 = DataFrame(readdlm("Donnees\\USCrime.html", skipstart = 38,
#   comments = true, comment_char = '<'))
# rename!(uscrime2, [:R,:Age,:S,:Ed,:Ex0,:Ex1,:LF,:M,:N,:NW,:U1,:U2,:W,:X])

print(cor(convert(Array{Float64}, uscrime))[:,1])
print(cortest(convert(Array{Float64}, uscrime))[:,1])
mod = lm(@formula(R ~ Age + S + Ed + Ex0 + Ex1 + LF + M +
  N + NW + U1 + U2 + W + X), uscrime)
print(mod)
