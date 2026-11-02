# EF - Pregunta 1: Probabilidades empíricas (Twitch)
library(readr)
DF <- read_csv("TwitchAF.csv")

X <- DF$Streamers > 10000   # más de 10000 streamers
Y <- DF$PromCan < 200       # menos de 200 canales en promedio
U <- DF$Mes == "Mayo"       # mes de mayo
O <- DF$`Año` != 2020       # no es del año 2020

mean(X, na.rm = TRUE)                    # P(X)        0.5084
mean(Y, na.rm = TRUE)                    # P(Y)        0.6369
mean(U, na.rm = TRUE)                    # P(U)        0.0858
mean(O, na.rm = TRUE)                    # P(O)        0.8853
mean(X & Y, na.rm = TRUE)                # P(X y Y)    0.1296
mean(U | O, na.rm = TRUE)                # P(U o O)    0.8948
mean(!U & !Y, na.rm = TRUE)              # P(no U y no Y)  0.3213
mean(!(X & Y) & !(U | O), na.rm = TRUE)  # P(no(X y Y) y no(U o O))  0.0826
