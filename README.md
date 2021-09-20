Julia
# 1) 3 choix techniques importants
LLVM (indépendance machine et code)

JIT

Typage dynamique
# 2) Permettent une grande efficacité sur
les calculs classiques

le dispatch multiple (connu depuis longtemps) (https://medium.com/swlh/how-julia-uses-multiple-dispatch-to-beat-python-8fab888bb4d8)

la métaprogrammation (idem)

en gardant le langage interprété : exécution par bouts, introspection.
# 3) Une conséquence importante de l’efficacité
La plupart des packages Julia sont entièrement en Julia. Alors, deux conséquences :

Plus facile à développer et maintenir qu’un package composite, donc croissance plus rapide de l’écosystème.

Méta programmation possible. On peut calculer la différentielle d’une fonction thermohydraulique, profiler toute fonction, etc.
# 4) Par ailleurs, langage récent :
Reprise de bonnes idées apparues récemment 

Parallèle (MPI, OpenMP, GPGPU).

Grosses données

Packaging prend en compte les versions des packages

…

Pour un exemple de dispatch multiple : dans «Distributions.jl: Definition and Modeling of Probability Distributions in the JuliaStats Ecosystem » paragraphe « 5.1. Maximum Likelihood Estimation » et « D.3. Product distribution model ».

Puis installation avec VSCode, et exercice sur NYC ou gesdon, en gardant néanmoins cortest de lineiairesig.



Contreproposition de Cyrille
# Parti-pris de Julia et conséquences :
## Interactif + orientation calcul scientifique (HPC) 
- **Parti pris** : Typage dynamique : Le typage permet au compilateur de générer du code spécialisé et ainsi plus efficace 
- **Conséquence** : Contrairement à Python ou R, Julia permet de limiter l’usage d’un 2e langage de programmation bas niveau comme C/C++ pour les sections critiques du code 
## Expressivité 
- **Parti pris** : Domaine specific language ou DSL -> métaprogrammation et génération de code (macro) basé sur l’arbre syntaxique et accès à l’annotation des types fait par le compilateur 
- **Conséquence** : support de plusieurs paradigmes de programmation (impératif, …)

