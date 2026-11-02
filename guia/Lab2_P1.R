# Lab 2 - Pregunta 1: Exploración de la etapa eliminatoria (Atletismo)
library(readr)
DF <- read_csv("Eliminatoria-3.csv")

str(DF)                       # 32 obs. de 8 variables
nrow(DF)                      # 32 observaciones
ncol(DF)                      # 8 variables
sum(complete.cases(DF))       # 32 -> no hay NA
length(unique(DF$País))       # 16 países
sum(DF$Primeros)              # 27 primeros lugares
sum(DF$Segundos)              # 24 segundos lugares
sum(DF$Terceros)              # 25 terceros lugares
