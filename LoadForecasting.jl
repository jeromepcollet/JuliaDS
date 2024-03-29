using DataFrames
using CSV
using Dates
using Pipe
using Interpolations
using StatsBase
using GLM
using CategoricalArrays
using TableView
using AlgebraOfGraphics
using GLMakie
GLMakie.activate!(inline=true)
# utilisation de Makie
# using WGLMakie


tempcol =
  @pipe CSV.read("Data\\Temperature.txt", DataFrame) |>
        # (CSV.File(open(read, "Data\\Temperature.txt")) |> DataFrame) |>
        transform!(_, :Date => (x -> DateTime.(x, dateformat"dd/mm/yyyy")) => :Date) |>
        stack(_, 2:9, [:Date]) |>
        transform(_,
          [:Date, :variable] => ((x, y) -> x + Dates.Minute.(parse.(Int64, y) .* 30)) => :Datim) |>
        select(_, :Datim, :value) |>
        rename(_, :value => :temp) |>
        sort(_, :Datim)
itp = LinearInterpolation(datetime2unix.(tempcol.Datim), tempcol.temp,
  extrapolation_bc=Line())

calendar =
  @pipe CSV.read("Data\\SpecialDays.txt", DataFrame) |>
        # @pipe (CSV.File(open(read, "Data\\SpecialDays.txt")) |> DataFrame) |>
        transform!(_, :Date => (x -> Date.(x, dateformat"dd/mm/yyyy")) => :Date)

loadcol =
  @pipe CSV.read("Data\\Load_2003.txt", DataFrame) |>
        # @pipe (CSV.File(open(read, "Data\\Load_2003.txt")) |> DataFrame) |>
        transform!(_, :Date => (x -> Date.(x, dateformat"dd/mm/yyyy")) => :Date) |>
        stack(_, 2:49, [:Date]) |>
        transform(_,
          :variable => (x -> Time.(x, dateformat"HH:MM")) => :variable) |>
        transform(_,
          [:Date, :variable] => ((x, y) -> x + y) => :Datim) |>
        select(_, :Datim, :value) |>
        rename(_, :value => :load) |>
        sort(_, :Datim)

normaldays = @pipe rightjoin(tempcol, loadcol, on=:Datim) |>
                   sort(_, :Datim) |>
                   transform(_, :Datim => (x -> itp(datetime2unix.(x))) => :temp) |>
                   transform(_, :Datim => (x -> Dates.Date.(x)) => :Date) |>
                   transform(groupby(_, :Date), :temp => mean)

formodel0 = @pipe leftjoin(normaldays, calendar, on=:Date) |>
                  transform(_, :Curtailment => (x -> ifelse.(ismissing.(x), 0, x)) => :Curtailment) |>
                  transform(_, [:Holidays, :Datim] => ((x, y) -> categorical(ifelse.(ismissing.(x), Dates.dayofweek.(y), 8))) => :type) |>
                  transform(_, :Date => (x -> ifelse.((x .> Date(2003, 3, 26)) .& (x .< Date(2003, 10, 26)), 1, 0)) => :DST) |>
                  transform(_, :Datim => (x -> categorical(Dates.hour.(x) + Dates.minute.(x) / 60)) => :h) |>
                  transform(_, :Datim => (x -> 2 * pi * Dates.datetime2julian.(x) / (365.25)) => :posyear)

elbow =
  @pipe formodel0 |>
        subset(_, :h => ByRow(x -> x == 12)) |>
        subset(_, :type => ByRow(x -> x in [1, 2, 3, 4, 5])) |>
        transform(_, :load => (x -> (x / 1000)) => :load) |>
        data(_) * mapping(
          :temp => "Temperature (°C)",
          :load => "Load at noon, normal day (GW)",) |>
        draw(_)
elbow
save("elbow2.png", elbow)

formodel = @pipe formodel0 |>
                 transform(_, :posyear => (x -> cos.(x)) => :a1) |>
                 transform(_, :posyear => (x -> sin.(x)) => :b1) |>
                 transform(_, :posyear => (x -> cos.(2 * x)) => :a2) |>
                 transform(_, :posyear => (x -> sin.(2 * x)) => :b2) |>
                 transform(_, :posyear => (x -> cos.(3 * x)) => :a3) |>
                 transform(_, :posyear => (x -> sin.(3 * x)) => :b3) |>
                 transform(_, :temp_mean => (x -> max.(16 .- x, 0)) => :tsmth) |>
                 transform(_, :temp => (x -> max.(16 .- x, 0)) => :tth) |>
                 transform(_, :temp_mean => (x -> max.(x .- 18, 0)) => :tsmtc) |>
                 transform(_, :temp => (x -> max.(x .- 18, 0)) => :ttc) |>
                 sort(_, :Datim)

# https://github.com/JuliaStats/GLM.jl/issues/426
lmod = lm(@formula(load ~
    type * h + h * DST + type * DST + Curtailment * h +
    a1 * h * DST + a2 * h + b1 * h * DST + b2 * h +
    tth * h + tsmth * h +
    tsmtc * h + posyear),
  formodel, dropcollinear=true)
sqrt(deviance(lmod) / dof_residual(lmod))
lmod = lm(@formula(load ~
    type * h + h * DST + type * DST + Curtailment * h +
    a1 * h * DST + a2 * h + b1 * h * DST + b2 * h +
    tth * h + tsmth * h +
    tsmtc * h + posyear
    + tsmth * posyear + a3 * h + b3 * h),
  formodel, dropcollinear=false)
sqrt(deviance(lmod) / dof_residual(lmod))

forlightinfluence =
  @pipe formodel |>
        transform(_, :Curtailment => (x -> 0) => :Curtailment) |>
        transform(_, :type => (x -> 1) => :type) |>
        transform(_, :tth => (x -> 0) => :tth) |>
        transform(_, :tsmth => (x -> 0) => :tsmth) |>
        transform(_, :tsmtc => (x -> 0) => :tsmtc) |>
        subset(_, :h => ByRow(x -> (mod.(convert.(Float64, x), 6) == 0)))
# transform(_, [:Curtailment, :DST, :a1, :a2, :b1, :b2, :h, :posyear, :tsmtc, :tsmth, :tth, :type] => 
# (predict(lmod, _)) => :pred) # ??????
lightinfluence = @pipe hcat(DataFrame(pred=predict(lmod, forlightinfluence)),
                         forlightinfluence) |>
                       transform(_, :pred => (x -> (x / 1000)) => :pred) |>
                       data(_) * mapping(
                         :Date => "Date",
                         :pred => "Seasonal part of forecast (GW)",
                         color=:h) |>
                       draw(_)
lightinfluence
save("lightinfluence2.png", lightinfluence)

resdens =
  @pipe hcat(DataFrame(pred=predict(lmod, formodel)), formodel) |>
        transform(_, [:pred, :load] => ((x, y) -> (x - y) ./ 1000) => :residuals) |>
        data(_) *
        mapping(:residuals) *
        AlgebraOfGraphics.density(datalimits=extrema) |>
        draw(_)
resdens
save("resdens2.png", resdens)