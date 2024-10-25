make_copy <- function(var_name, append=".old", envir=.GlobalEnv) {
  assign(paste0(var_name, append), get(var_name, envir=envir), envir = envir)
}