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
  @pipe (CSV.File(open(read, "Data\\Temperature.txt")) |> DataFrame) |>
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
  @pipe (CSV.File(open(read, "Data\\SpecialDays.txt")) |> DataFrame) |>
  transform!(_, :Date => (x-> Date.(x, dateformat"dd/mm/yyyy")) => :Date)
# DataFramesMeta, Chain, Lazy, Pipe, voire Query

loadcol =
  @pipe (CSV.File(open(read, "Data\\Load_2003.txt")) |> DataFrame) |>
    transform!(_, :Date => (x-> Date.(x, dateformat"dd/mm/yyyy")) => :Date) |>
    stack(_ ,2:49, [:Date]) |>
    transform(_,
        :variable => (x-> Time.(x, dateformat"HH:MM")) => :variable) |>
    transform(_,
        [:Date,:variable] => ((x,y)-> x + y) => :Datim)|>
        select(_, :Datim, :value)|>
        rename(_, :value => :load)|>
        sort(_, :Datim)

normaldays = @pipe rightjoin(tempcol, loadcol, on = :Datim)|>
  sort(_, :Datim)|>
  transform(_, :Datim => (x -> itp(datetime2unix.(x))) => :temp)|>
  transform(_, :Datim => (x -> Dates.Date.(x)) => :Date)|>
  transform(groupby(_, :Date), :temp => mean)

# traitement vilain des dates
# pb sur le calendrier, surtout les Curtailment
pourmodel = @pipe leftjoin(normaldays, calendar, on = :Date)|>
  transform(_, :Curtailment => (x -> ifelse.(ismissing.(x), 0, x)) => :Curtailment)|>
  transform(_, [:Holidays,:Datim] => ((x,y) -> categorical(ifelse.(ismissing.(x), Dates.dayofweek.(y), 8))) => :type)|>
  transform(_, :Date => (x -> ifelse.((x .> Date(2003, 3, 26)) .& (x .< Date(2003, 10, 26)), 1, 0)) => :DST)|>
  transform(_, :Datim => (x -> categorical(2 * Dates.hour.(x) + Dates.minute.(x) / 30)) => :h)|>
  transform(_, :Datim => (x -> 2 * pi * Dates.datetime2epochms.(x) / (365.25 * 86400 * 1000)) => :posyear)|>
  transform(_, :posyear => (x -> cos.(x)) => :a1)|>
  transform(_, :posyear => (x -> sin.(x)) => :b1)|>
  transform(_, :posyear => (x -> cos.(2 * x)) => :a2)|>
  transform(_, :posyear => (x -> sin.(2 * x)) => :b2)|>
  transform(_, :posyear => (x -> cos.(3 * x)) => :a3)|>
  transform(_, :posyear => (x -> sin.(3 * x)) => :b3)|>
  transform(_, :temp_mean => (x -> max.(16 .- x, 0)) => :tsmth)|>
  transform(_, :temp => (x -> max.(16 .- x, 0)) => :tth)|>
  transform(_, :temp_mean => (x -> max.(x .- 18, 0)) => :tsmtc)|>
  transform(_, :temp => (x -> max.(x .- 18, 0)) => :ttc)|>
  sort(_, :Datim)

#=
Gadfly.plot(pourmodel, x = :Datim, y = :a1, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :b1, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :a2, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :b2, Geom.line)
Gadfly.plot(pourmodel, x = :temp, y = :tth, Geom.line)
Gadfly.plot(pourmodel, x = :temp_mean, y = :tsmth, Geom.line)
Gadfly.plot(pourmodel, x = :temp, y = :ttc, Geom.line)
Gadfly.plot(pourmodel, x = :temp_mean, y = :tsmtc, Geom.line)
Gadfly.plot(pourmodel, x = :Datim, y = :Curtailment, Geom.line)
 =#

sum(pourmodel.Curtailment)
sum(calendar.Curtailment)

# showtable(pourmodel)
# https://github.com/JuliaStats/GLM.jl/issues/426
mod = lm(@formula(load ~
    type*h + h*DST + type*DST + Curtailment*h +
    a1*h*DST + a2*h + b1*h*DST + b2*h +
    tth*h + tsmth*h +
    tsmtc*h + posyear),
    pourmodel, dropcollinear=true)
sqrt(deviance(mod)/dof_residual(mod))
mod = lm(@formula(load ~
    type*h + h*DST + type*DST + Curtailment*h +
    a1*h*DST + a2*h + b1*h*DST + b2*h +
    tth*h + tsmth*h +
    tsmtc*h + posyear
    + tsmth*posyear + a3*h + b3*h),
    pourmodel, dropcollinear=false)
sqrt(deviance(mod)/dof_residual(mod))
