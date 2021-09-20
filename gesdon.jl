# using DelimitedFiles
using DataFrames
using CSV
using Dates
using Pipe
using TableView
using Interpolations
using StatsBase
using GLM
using Plots
using Gadfly
using CategoricalArrays

#=
stack
transform
dates
interpolation
join
group_by
glm, avec interactions
=#

tempcol =
  @pipe (CSV.File(open(read, "Donnees\\TREA03L_V1_040419.txt")) |> DataFrame) |>
    transform!(_, :Date => (x-> DateTime.(x, dateformat"dd/mm/yyyy")) => :Date) |>
    stack(_ ,2:9, [:Date]) |>
    transform(_,
        [:Date,:variable] => ((x,y)-> x + Dates.Minute.(parse.(Int64,y).*30)) => :Datim)|>
        select(_, :Datim, :value)|>
        rename(_, :value => :temp)|>
        sort(_, :Datim)
itp = LinearInterpolation(datetime2unix.(tempcol.Datim), tempcol.temp,
  extrapolation_bc = Line())

calendar =
  @pipe (CSV.File(open(read, "Donnees\\speciaux.txt")) |> DataFrame) |>
  transform!(_, :Date => (x-> Date.(x, dateformat"dd/mm/yyyy")) => :Date)
# DataFramesMeta, Chain, Lazy, Pipe, voire Query

consocol =
  @pipe (CSV.File(open(read, "Donnees\\historique_consommation_puissance_2003.txt")) |> DataFrame) |>
    transform!(_, :Date => (x-> Date.(x, dateformat"dd/mm/yyyy")) => :Date) |>
    stack(_ ,2:49, [:Date]) |>
    transform(_,
        :variable => (x-> Time.(x, dateformat"HH:MM")) => :variable) |>
    transform(_,
        [:Date,:variable] => ((x,y)-> x + y) => :Datim)|>
        select(_, :Datim, :value)|>
        rename(_, :value => :conso)|>
        sort(_, :Datim)

normaux = @pipe rightjoin(tempcol, consocol, on = :Datim)|>
  sort(_, :Datim)|>
  transform(_, :Datim => (x -> itp(datetime2unix.(x))) => :temp)|>
  transform(_, :Datim => (x -> Dates.Date.(x)) => :Date)|>
  transform(groupby(_, :Date), :temp => mean)

# traitement vilain des dates
# pb sur le calendrier, surtout les ejp
pourmodel = @pipe leftjoin(normaux, calendar, on = :Date)|>
  transform(_, :ejp => (x -> ifelse.(ismissing.(x), 0, x)) => :ejp)|>
  transform(_, [:fete,:Datim] => ((x,y) -> categorical(ifelse.(ismissing.(x), Dates.dayofweek.(y), 8))) => :type)|>
  transform(_, :Date => (x -> ifelse.((x .> Date(2003, 3, 26)) .& (x .< Date(2003, 10, 26)), 1, 0)) => :cheure)|>
  transform(_, :Datim => (x -> categorical(2 * Dates.hour.(x) + Dates.minute.(x) / 30)) => :h)|>
  transform(_, :Datim => (x -> 2 * pi * Dates.datetime2epochms.(x) / (365.25 * 86400 * 1000)) => :posan)|>
  transform(_, :posan => (x -> cos.(x)) => :a1)|>
  transform(_, :posan => (x -> sin.(x)) => :b1)|>
  transform(_, :posan => (x -> cos.(2 * x)) => :a2)|>
  transform(_, :posan => (x -> sin.(2 * x)) => :b2)|>
  transform(_, :posan => (x -> cos.(3 * x)) => :a3)|>
  transform(_, :posan => (x -> sin.(3 * x)) => :b3)|>
  transform(_, :temp_mean => (x -> max.(16 .- x, 0)) => :tlish)|>
  transform(_, :temp => (x -> max.(16 .- x, 0)) => :tsh)|>
  transform(_, :temp_mean => (x -> max.(x .- 18, 0)) => :tlisc)|>
  transform(_, :temp => (x -> max.(x .- 18, 0)) => :tsc)|>
  sort(_, :Datim)

#=
Gadfly.plot(pourmodel, x = :Datim, y = :a1, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :b1, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :a2, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :b2, Geom.line)
Gadfly.plot(pourmodel, x = :temp, y = :tsh, Geom.line)
Gadfly.plot(pourmodel, x = :temp_mean, y = :tlish, Geom.line)
Gadfly.plot(pourmodel, x = :temp, y = :tsc, Geom.line)
Gadfly.plot(pourmodel, x = :temp_mean, y = :tlisc, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :ejp, Geom.line)
 =#

sum(pourmodel.ejp)
sum(calendar.ejp)

# showtable(pourmodel)
# https://github.com/JuliaStats/GLM.jl/issues/426
mod = lm(@formula(conso ~
    type*h + h*cheure + type*cheure + ejp*h +
    a1*h*cheure + a2*h + b1*h*cheure + b2*h +
    tsh*h + tlish*h +
    tlisc*h + posan
    ), pourmodel, dropcollinear=false)
sqrt(deviance(mod)/dof_residual(mod))
mod = lm(@formula(conso ~
    type*h + h*cheure + type*cheure + ejp*h +
    a1*h*cheure + a2*h + b1*h*cheure + b2*h +
    tsh*h + tlish*h +
    tlisc*h + posan
    + tlish*posan + a3*h + b3*h
     ), pourmodel, dropcollinear=false)
sqrt(deviance(mod)/dof_residual(mod))
