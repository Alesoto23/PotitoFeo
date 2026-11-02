# EF - Pregunta 5: Validar un modelo geométrico para Streamers
library(readr)
DF <- read_csv("TwitchAF.csv")

m <- mean(DF$Streamers, na.rm = TRUE)
p <- 1 / (m + 1)                                     # parámetro geométrico

round(m, 2)                                          # media        34054.58
round(sqrt((1 - p) / p^2), 2)                        # sd teórica   34055.08
round(pgeom(m, p, lower.tail = FALSE), 2)            # P(X > media) 0.37

round(sd(DF$Streamers, na.rm = TRUE), 2)             # sd empírica  61174.47
round(mean(DF$Streamers > m, na.rm = TRUE), 2)       # P empírica   0.23
# sd teórica mucho menor que la empírica -> el modelo no es bueno
