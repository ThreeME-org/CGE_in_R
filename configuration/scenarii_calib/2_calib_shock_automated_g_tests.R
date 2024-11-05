## Automated shock by Maryeme for two variable
automated_calib_shock <- function( 
    scen_name = the_scenario,
    calib_base = calib_new_base,
    parameters_data_frame = parameters_range
    ){
  
  index_scenar <-which( parameters_data_frame$name == scen_name)
  
  series <- c("g", "y", ## variable a modifier pour le shock standard
              paramaters_variables ## variables parametrees anterieurement
              )   %>% tolower
  
  # Load the selected series for the range baseyear:lastyear
  selection <- calib_new_base %>% select(year,any_of(series))
  
  ## Change in exogenous variables
  #(1) Using formulas
  
  shock_ch <- mutate(selection,
                     
                     # Parametered shocks from the database
                     # rho_rn_p=  parameters_data_frame$rho_rn_p[index_scenar],
                     # rho_rn_u=  parameters_data_frame$rho_rn_u[index_scenar],
                      rho_kl=  parameters_data_frame$rho_kl[index_scenar],
                     
                     # shock commun
                     g = ifelse(year >= 2021, g + parameters_data_frame$g_shock[index_scenar]*y, g)
                     
  ) %>% select(year, any_of(series)) 
  
  
}
