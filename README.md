# Brief presentation of Julia

## 1) 3 choix techniques importants

LLVM (indépendance machine et code)

JIT

Typage dynamique

## 2) Permettent une grande efficacité sur

les calculs classiques

le dispatch multiple (connu depuis longtemps) (https://medium.com/swlh/how-julia-uses-multiple-dispatch-to-beat-python-8fab888bb4d8)

la métaprogrammation (idem)

en gardant le langage interprété : exécution par bouts, introspection.
## 3) Une conséquence importante de l’efficacité
La plupart des packages Julia sont entièrement en Julia. Alors, deux conséquences :

Plus facile à développer et maintenir qu’un package composite, donc croissance plus rapide de l’écosystème.

Méta programmation possible. On peut calculer la différentielle d’une fonction thermohydraulique, profiler toute fonction, etc.
## 4) Par ailleurs, langage récent :
Reprise de bonnes idées apparues récemment 

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
