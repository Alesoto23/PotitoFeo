# Lab 2 - Pregunta 3: Mínimo, máximo y mediana de corredoras por país
library(readr)
DF <- read_csv("Eliminatoria-3.csv")

TP <- table(DF$País)
min(TP)              # 1  (mínimo)
max(TP)              # 7  (máximo: Estados Unidos)
median(TP)           # 2  (mediana)
sort(TP)             # para verlo ordenado
