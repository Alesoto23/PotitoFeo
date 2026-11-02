# Lab 2 - Preguntas 5 a 8: probabilidad clásica y conteo de grupos
library(readr)
DF <- read_csv("Eliminatoria-3.csv")

table(DF$País)[c("Perú", "Guatemala", "Trinidad")]           # 3, 1, 2

# P5: ganadora peruana = favorables / posibles
round(sum(DF$País == "Perú") / nrow(DF), 2)                  # 0.09

# P6: formas de armar las 4 carreras de 8 (las tres expresiones dan lo mismo)
factorial(32) / factorial(8)^4
choose(32,8) * choose(24,8) * choose(16,8) * choose(8,8)
choose(4,1) * choose(31,7) * choose(24,8) * choose(16,8) * choose(8,8)

# P7: hay 1 sola guatemalteca -> siempre queda "junta"        # 1

# P8: las 2 trinitarias en la misma carrera de 8, pasan 1º y 2º
round(1 / choose(8, 2), 2)                                   # 0.04
