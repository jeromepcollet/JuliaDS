# Brief presentation of Julia

## Core choices

Quoted from   [Why Does Julia Work So Well?](https://ucidatascienceinitiative.github.io/IntroToJulia/Html/WhyJulia): The core design decision, **type-stability through specialization via multiple-dispatch** is what allows Julia to be very easy for a compiler to make into efficient code, but also allow the code to be very concise and "look like a scripting language". This will lead to some very clear performance gains.

Other key choice : metaprogramming. Like Lisp, Julia represents its own code as a data structure of the language itself. Since code is represented by objects that can be created and manipulated from within the language, it is possible for a program to transform and generate its own code

## Main consequences of Julia's efficiency

### Solves the two languages problem
Due to Julia speed, it is it is no longer useful to write the compuational core of a package in Fortran or C. So, a large proportion of Julia packages are written entirely in Julia.

Therefore, the growth of the Julia ecosystem is much faster than others.

Furthermore, the metaprogramming capabilities of Julia are then extended to the packages written in Julia. For example, it is possible to compute the differential of a whole Julia function, in many packages. It is also possible to profile thsese packages, etc.

### Domain Specific Languages 
It is a consequence of metaprogramming : since the beginning of Julia, it has been tempting to use macros to write domain-specific languages (DSLs), i.e. to extend Julia syntax to provide a simpler interface to create Julia objects with complicated behaviour. The first, and still most extensive, example is [JuMP](https://github.com/jump-dev/JuMP.jl). 

## Other useful features, due to language novelty

Julia provides native parallel computation capabilities, use of GPGPU, plus links with many parallel computation framework : MPI, OpenMP.

It is possible to process large amounts of data using Julia.

Julia allows to manage the version of each package used, like Python’s `virtualenv` or Ruby’s `bundler`.


# This load forecasting problem

## The story

The variable we try to forecast is the electric load.

There is obviously a strong influence of day-type and hour. There is also an influence of the position in the year. The main cause of this influence is the variation of the day light: at 6am, we do not need electric light in summer, and we do need it in winter.

Another important variable is the temperature, since 30% of households in France use electric heating. A simple modelling is to use a linear spline: constant slope up to approximately 18°C, and then a slope equal to 0. The same is done for the cooling. Furthermore, it is useful to use a smoothed temperature jointly to the raw temperature.

An important feature, in 2003, was the use by EDF (frenc electric utility) of load curtailment signals.

## The data

We have 3 files:

* The load, with a value each half-hour. The 48 values of each day are on the same line.
* The temperatures, with a value each 3 hours. The 8 values of each day are on the same line.
* The special days: holidays and load curtailment days.

## The Julia tools

We use:

* `stack` of package `DataFrames` to put in one column the load and temperature data.
* `transform` of package `DataFrames` to create new variables, for example a datetime variable, after stacking the load and temperature data.
* `interpolation`of package `Interpolations`, to interpolate the temperature.
* `join` of package `DataFrames` to join all variables. For temperature and load, a simple binding of the dataframes would be enough, since they have the same time-step. For the information about special days, we join daily information with half-hourly information, a proper join is compulsory.
* `group_by` of package `DataFrames` is useful to compute a smoothed temperature: we use a daily averaged emperature.
* `lm`of package `glm`, is used to ultimately model the data we built. An important feature of this function is the modelling of interactions : `tth*h` means that the coefficient of the continous variable `tth` (the temperature, thresholded at 18°C) depends of the value of the categorical variable `h`, which is the hour.

Results:
* the `lm` function causes some issues, since the model is very ill-conditioned see https://github.com/JuliaStats/GLM.jl/issues/426.
* The root mean square error of the model is around 1600 MW, which is twice the RMSE of professional models. The main part of the work to improve this model is the careful processing of special days: we did not take account of days before and after special days, of bridges, August and Christmas periods, etc. Once this processing is done, the remain is fine tuning of temperature representation, etc.
