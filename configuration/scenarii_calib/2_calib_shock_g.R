## 1% GDP point increase of public expenditure


# Define the series necessary to calibrate the scenario  
series <- c("G", "Y") %>% tolower
 
# Load the selected series for the range baseyear:lastyear
selection <- calib_new_base %>% select(year,all_of(series))


## Change in exogenous variables
#(1) Using formulas
shock_ch <- mutate(selection,
                   g = ifelse(year >= 2021, g + 0.01*y, g)

                   )  %>% select(-y)

#  Examples of calibration using mutate
# examples_with_mutate <- mutate(selection,
# 
#     ex01 =   ifelse(year >= 2021, g + 1, g),    # Permanent shock
#     ex02 =   ifelse(year >= 2021, g + 0.01*y[which(year == 2021)], g), # Permanent shock
#                                          # Proportional to the base year value of another variable
#     ex03 =   ifelse(year >= 2021, g + 0.01*y, g), # Permanent shock
#                   # Proportional to the baseline value of another variable 
#                    # (magnitude of the shock is not sensitive to the economic growth assumption)
#     ex04 =   ifelse(year == 2021, g + 0.01*y[which(year == 2021)], g),           # Transitory shock  (only one year)
#     ex05 =   ifelse(year == shockyear, g + 0.01*y[which(year == shockyear)], g), # Transitory shock (only one year)
#     ex06 =   ifelse(year %in% c(2021:2025), g + 0.01*y[which(year == 2021)], g), # Transitory shock (several years)
#     ex07 =   ifelse(year %in% c(shockyear:2025), g + 0.01*y, g),          # Transitory shock (several years)
#     ex08 =   ifelse(year %in% c(shockyear:(shockyear+5)), g + 0.01*y, g)  # Transitory shock (several year)
#                    
#                    )  %>% select(-y)
# 
