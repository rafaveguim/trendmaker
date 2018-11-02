install.packages("checkpoint")
install.packages("devtools")
install.packages("here")

library(checkpoint)
dir.create("~/.checkpoint/2018-08-01", recursive=TRUE)
checkpoint("2018-08-01", scanForPackages = TRUE, forceProject=TRUE)

library(here)
library(devtools)

setwd(here())

cat("Current working directory: ", getwd(), "\n")

install_github('timelyportfolio/reactR')


# print(file.exists("~/.checkpoint"))
checkpoint("2018-08-01", scanForPackages = TRUE, forceProject=TRUE)