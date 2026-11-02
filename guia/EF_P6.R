# EF - Pregunta 6: Gráfica comparativa, muestra vs modelo gamma
library(readr)
DF <- read_csv("TwitchAF.csv")

sha <- 1.92; rat <- 0.05
Z <- DF$PromEsp / DF$PromCan

round(mean(Z, na.rm = TRUE), 2)                          # 39.56
round(median(Z, na.rm = TRUE), 2)                        # 28.68 -> media > mediana: sesgo a la derecha
round(IQR(Z, na.rm = TRUE), 2)                           # IQR empírico 35.74
round(diff(qgamma(c(.25, .75), sha, rat)), 2)            # IQR teórico  33.78 (menor)
sum(!is.na(Z)); round(max(Z, na.rm = TRUE), 2)           # 1965 y 227.79 (no se lee en la gráfica)
round(mean(Z > 50, na.rm = TRUE), 2)                     # 0.28 (Q3 empírico 53.56 > 50)
round(pgamma(50, sha, rat) - pgamma(12.5, sha, rat), 2)  # 0.59 (requiere cálculo)
round(pgamma(50, sha, rat, lower.tail = FALSE), 2)       # 0.27 (Q3 teórico 51.84 > 50)
