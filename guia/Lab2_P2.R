# Lab 2 - Pregunta 2: Corredoras por país (promedio, sd y CV)
library(readr)
DF <- read_csv("Eliminatoria-3.csv")

TP <- table(DF$País)            # número de corredoras por país
round(mean(TP), 2)              # promedio  2
round(sd(TP), 2)                # sd        1.51
round(sd(TP) / mean(TP), 2)     # CV        0.75  (en porcentaje: 75.28)
