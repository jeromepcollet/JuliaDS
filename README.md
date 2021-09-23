# Brief presentation of Julia

Core Idea: Multiple Dispatch + Type Stability => Speed + Readability ; developed in  [Why Does Julia Work So Well?](https://ucidatascienceinitiative.github.io/IntroToJulia/Html/WhyJulia)

Other key choice : metaprogramming. Like Lisp, Julia represents its own code as a data structure of the language itself. Since code is represented by objects that can be created and manipulated from within the language, it is possible for a program to transform and generate its own code

## Main consequences of Julia's efficiency

### Solves the two languages problem
Due to Julia speed, it is it is no longer useful to write the compuational core of a package in Fortran or C. So, a large proportion of Julia packages are written in Julia. Therefore, the growth of the Julia ecosystem is much faster than others. Furthermore, the metaprogramming capabilities of Julia are then extended to the  packages written in Julia. For example, it is possible to compute the differential of a whole Julia function, in many packages. It is also possible to profile thsese packages, etc.

### Domain Specific Languages 
It is a consequence of metaprogramming : since the beginning of Julia, it has been tempting to use macros to write domain-specific languages (DSLs), i.e. to extend Julia syntax to provide a simpler interface to create Julia objects with complicated behaviour. The first, and still most extensive, example is [JuMP](https://github.com/jump-dev/JuMP.jl). 

## Other useful features, due to language novelty

Julia allows the use of many parallel computation framework : MPI, OpenMP, GPGPU.

It is pssible to process large amounts of data using Julia.

Julia allows to manage the version of each package used, like Python’s virtualenv or Ruby’s bundler.

# This load forecasting problem

## The story

Influence of hour in the week; of the position in the year (light).

Influence of temperature (30% of households in France with electric heating).

## The data

## The Julia tools

stack

transform

dates

interpolation

join

group_by

glm, avec interactions
