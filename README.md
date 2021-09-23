# Brief presentation of Julia

Main idea : Core Idea: Multiple Dispatch + Type Stability => Speed + Readability

developed in  [Why Does Julia Work So Well?](https://ucidatascienceinitiative.github.io/IntroToJulia/Html/WhyJulia)

## Main consequences of Julia's efficiency

### Solves the two languages problem
La plupart des packages Julia sont entièrement en Julia. Alors, deux conséquences :
Plus facile à développer et maintenir qu’un package composite, donc croissance plus rapide de l’écosystème.
On peut calculer la différentielle d’une fonction thermohydraulique, profiler toute fonction, etc.
### Allows Domain Specific Language via metaprogramming
Voir

## Other useful features, due to language novelty

Parallèle (MPI, OpenMP, GPGPU).

Grosses données

Packaging prend en compte les versions des packages

# This load forecasting problem

## The story

Influence of hour in the week; of the position in the year (light).

Influence of temperature (30% of households in France with electric heating).

## The Julia tools

stack

transform

dates

interpolation

join

group_by

glm, avec interactions
