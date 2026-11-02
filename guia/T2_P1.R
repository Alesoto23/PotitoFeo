# T2 - Pregunta 1: Exploración de la base Cuy (Cuytopia)
library(readr)
library(dplyr)

DF <- read_csv("Cuy_InicialYPiloto.csv")

dim(DF)                     # 8755 observaciones de 13 variables
sapply(DF, class)           # tipo de cada variable
sapply(DF, n_distinct)      # valores distintos por variable

# Nominales (6): Raza, Sexo, Color, Reporte, Equipo, Error
# Ordinal (1): Talla | Fecha (1): Fecha
# Numéricas (5): Peso, Largo, Cintura, Edad, Tiempo -> discretas (4): Peso, Largo, Cintura, Edad

n_distinct(DF$Tiempo)       # 8574 valores distintos -> tabla de frecuencias absurda

head(DF$Reporte)            # no prolija: Ser. No., Date y Status en una celda
head(DF$Fecha)              # podría no estar prolija: fecha y hora juntas

sum(!complete.cases(DF))    # 4748 observaciones incompletas
