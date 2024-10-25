## ThreeME initialisation file 
options(scipen = 14)

if(paste(R.version$major,R.version$minor, sep = ".") < "4.3.1"){

  stop( "\U1F4A3 \U1F4A3 Please update your R version to at least 4.3.1")
}

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
                       "crayon","beepr","learnr", "DiagrammeR", "quarto",
                       "fst", "microbenchmark", "tictoc","dtplyr")

not_installed_CRAN <-  required_CRAN_packages[!(required_CRAN_packages     %in% installed.packages()[ , "Package"])]

if(length(not_installed_CRAN)>0){pak::pak(not_installed_CRAN)}
## GitHub packages
# 
required_GIT_packages <-  c("ofce","ermeeth","tresthor","pegr")
# pak::pak("OFCE/ofce",ask = FALSE)
# pak::pak("OFCE/tresthor",ask = FALSE)
# if( !"pegr" %in% installed.packages()[ , "Package"]){pak::pak("mslegrand/pegr",ask = FALSE)}
# pak::pak("ThreeME-org/ermeeth",ask = FALSE)

# NB: "require" is equivalent to "library" but is designed for use inside other functions.

purrr::map(c(required_CRAN_packages,required_GIT_packages),~require(.x,character.only = TRUE))

purrr::map(list.files(file.path("src","functions_src","")),~source(file.path("src","functions_src",.x)))

rm(not_installed_CRAN, required_GIT_packages)
