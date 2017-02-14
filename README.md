# safeauto-cia
This repository contains the R code for visualizing CIA data from SafeAuto.

# Packages used
shiny, data.table, DT, plotly, h2o, lubridate, devtools, googleVis, sunburstR

# Note
To install googleVis and sunburstR, run the following commands:

install.packages(c("devtools","RJSONIO", "knitr", "shiny", "httpuv"))

library(devtools)

install_github("mages/googleVis")

install_github("timelyportfolio/sunburstR")

# How to run
1. Make sure safeAuto_data_challenge.csv is placed in the same directory as ui.R and server.R files.
2. runApp()
