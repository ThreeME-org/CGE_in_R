rm(list = ls())

if("pak" %in% installed.packages()[ , "Package"] == FALSE){
  install.packages("pak")
}
if("tidyverse" %in% installed.packages()[ , "Package"] == FALSE){
  install.packages("tidyverse")
}

library(tidyverse)
library(pak)

required_CRAN_packages <- c("data.table", "lemon", "tidyverse", "extrafont", "scales", "readxl",
                            "colorspace", "ggpubr", "svglite", "magrittr", "png", "remotes","glue", "flextable",
                            "Deriv", "splitstackshape", "gsubfn", "cointReg","RcppArmadillo","Rcpp","zip",
                            "devtools","eurostat","RJSONIO","rdbnomics","rmarkdown","officer","shiny","ggh4x","openxlsx",
                            "stringr", "sys","ggpp","magick","qs","showtext","knitr","paletteer","countrycode","plotly",
                            "crayon","beepr","learnr", "DiagrammeR", "quarto","gt","downloadthis","PrettyCols",
                            "fst", "microbenchmark", "tictoc","dtplyr")

pak::pak(required_CRAN_packages)


pak::pak("OFCE/ofce",ask = FALSE)
pak::pak("OFCE/tresthor",ask = FALSE)
if( !"pegr" %in% installed.packages()[ , "Package"]){pak::pak("mslegrand/pegr",ask = FALSE)}
pak::pak("ThreeME-org/ermeeth",ask = FALSE)

rm(list = ls())


