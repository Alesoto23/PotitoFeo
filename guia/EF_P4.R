# EF - Pregunta 4: Función de densidad por partes
g <- function(x) ifelse(x > 0 & x <= 1, 4 - 3*(1 - x)^2,
                 ifelse(x > 1 & x <= 3, (x - 3)^2, 0))
k <- 1 / integrate(g, 0, 3)$value
f <- function(x) k * g(x)

round(k, 2)                                        # k          0.18
round(integrate(f, 1, 3)$value, 2)                 # P(X > 1)   0.47
E  <- integrate(function(x) x * f(x), 0, 3)$value
E2 <- integrate(function(x) x^2 * f(x), 0, 3)$value
S  <- sqrt(E2 - E^2)
round(E, 2)                                        # E(X)       1.01 horas
round(S, 2)                                        # sd         0.56 horas
round(S / E * 100, 2)                              # CV 55.52% > 30% -> mediana
