## check package installation and local availability
library(glue)

install_local <- function(nom_package){
  if(nom_package %in% installed.packages()){
    version_installed <- as.data.frame(installed.packages()) |> filter(Package == nom_package ) |>
      select(Version) |> unlist()
    
    cat(glue("{nom_package} is installed, version: {version_installed} \n
             
             "))
    
    ## Checking for newer sources 
    source_packages <- list.files("src",pattern = glue("^{nom_package}.+gz$")  )
    
    
    if(length(source_packages)>0){
      
      latest <- max(source_packages)
      
      version_available  <- latest |> str_extract("_(\\d+\\.)+") |>
        str_remove("_") |> str_remove("\\.$") 
      
      if(version_available>version_installed){
        
        cat(glue("A more recent version of {nom_package} package has been found: {version_available},. Installing this new version...\n"))
        
        install.packages(file.path("src",latest), repos = NULL, type = "source")
        
        cat(glue("Version {version_available} of {nom_package} package has been installed.\n"))
      }
    }
    
    
  }else{ 
    source_package <- list.files("src/",pattern = glue ("^{nom_package}.+gz$") )
    
    if(length(source_package)>0){
      
      latest <- max(source_package) 
      install.packages(file.path("src",latest), repos = NULL, type = "source") 
      
    }else{cat(glue(":( Could not find {nom_package} source package to install. :( \n"))}
    
  }
}


