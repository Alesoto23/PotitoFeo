# EF - Pregunta 3: Probabilidad total y Bayes, teórico vs empírico (Twitch)
library(readr)
DF <- read_csv("TwitchAF.csv")

# Modelo TEÓRICO del experto
PV <- 0.90*0.025 + 0.30*0.475 + 0.05*0.500
round(PV, 2)                         # P(V)      0.19
round(0.90*0.025 / PV, 2)            # P(A | V)  0.12

# Probabilidades EMPÍRICAS
A <- DF$Pos <= 5                     # entre las cinco mejores
V <- DF$Streamers >= 20000           # al menos 20000 streamers
round(mean(V, na.rm = TRUE), 2)      # P(V)      0.31
round(mean(A[V], na.rm = TRUE), 2)   # P(A | V)  0.21
# Experto 0.19 < observado 0.31 -> escenario más pesimista que el observado
