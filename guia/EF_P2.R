# EF - Pregunta 2: Probabilidad condicional e independencia (Twitch)
library(readr)
DF <- read_csv("TwitchAF.csv")

X <- DF$Streamers > 10000   # más de 10000 streamers
Y <- DF$PromCan < 200       # menos de 200 canales en promedio
E <- DF$Mes == "Enero"      # mes de enero
M <- DF$`Año` == 2024       # año 2024

round(mean(X[Y], na.rm = TRUE), 2)    # P(X | Y)     0.24
round(mean(X, na.rm = TRUE), 2)       # P(X)         0.51  -> distintas: dependientes

round(mean(E[!M], na.rm = TRUE), 2)   # P(E | no M)  0.08
round(mean(E, na.rm = TRUE), 2)       # P(E)         0.08  -> iguales: independientes
