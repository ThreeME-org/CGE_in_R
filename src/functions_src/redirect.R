redirect <- function(normal_path, redirect = path_main){
  if(is.null(redirect)){
    res <- file.path(normal_path)  
  }else{
    res <- file.path(paste0(redirect), normal_path)  
  }
  
  res |>  normalizePath()
}
