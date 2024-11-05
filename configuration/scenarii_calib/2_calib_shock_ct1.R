## 1 GDP point increase of carbon tax

# Define the series necessary to calibrate the scenario  
series <- c("GDP" ,"EMS_CI_CO2","EMS_MAT_CO2", "EMS_Y_CO2", "EMS_CH_CO2", "rco2tax_vol")   %>% tolower
 
# Load the selected series for the range baseyear:lastyear
selection <- calib_new_base %>% select(year,all_of(series))

## Change in exogenous variables
#(1) Using formulas

shock_ch <- mutate(selection,
                   ems_taxbasis = ems_ci_co2 + ems_mat_co2 + ems_y_co2+ems_ch_co2,
                   rco2tax_vol = ifelse(year >= shockyear, 
                                        rco2tax_vol + 0.01*gdp[which(year == shockyear)]/ems_taxbasis[which(year==shockyear)], rco2tax_vol)
                            ) %>% select(year, rco2tax_vol) 

