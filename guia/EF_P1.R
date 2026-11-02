# EF - Pregunta 1: Probabilidades empíricas (Twitch)
library(readr)
DF <- read_csv("TwitchAF.csv")

X <- DF$Streamers > 10000   # más de 10000 streamers
Y <- DF$PromCan < 200       # menos de 200 canales en promedio
U <- DF$Mes == "Mayo"       # mes de mayo
O <- DF$`Año` != 2020       # no es del año 2020

round(mean(X, na.rm = TRUE), 2)                    # P(X)  0.51
round(mean(Y, na.rm = TRUE), 2)                    # P(Y)  0.64
round(mean(U, na.rm = TRUE), 2)                    # P(U)  0.09
round(mean(O, na.rm = TRUE), 2)                    # P(O)  0.89
round(mean(X & Y, na.rm = TRUE), 2)                # P(X y Y)  0.13
round(mean(U | O, na.rm = TRUE), 2)                # P(U o O)  0.89
round(mean(!U & !Y, na.rm = TRUE), 2)              # P(no U y no Y)  0.32
round(mean(!(X & Y) & !(U | O), na.rm = TRUE), 2)  # P(no(X y Y) y no(U o O))  0.08
