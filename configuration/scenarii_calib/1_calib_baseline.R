## Baseline hypotheses calibrations

# Load calibration for range baseyear:lastyear
calib <- OGcalib %>% filter(year %in% c(firstyear:lastyear)) 

# Define the series necessary to calibrate the scenario  
series <- c("POP", "PROG_L") %>% tolower
 
# Load the selected series for the range baseyear:lastyear
selection <- calib %>% select(year)


## Change in exogenous variables
#(1) Using formulas

baseline_ch1 <- selection

# baseline_ch1 <- mutate(selection,
#                        pop = ifelse(year >= 2030, pop*1.001, pop),
#                        prog_l = ifelse(year >= 2030, prog_l*1.002, prog_l)
#                         ) 

# library(ggplot2)
# ggplot(data=baseline_ch, aes(x=year, y=prog_l)) + geom_line()

# Changes in stocks converge progressivelly to 0 
baseline_ch2 <- calib %>% select(year,starts_with("dsd_"),starts_with("dsm_"))

# Define lists
source(paste0("src/bridges/codenames_",classification,".R"))
list_com <- names_commodities %>% filter(!grepl('C0', code))
list_sec <- names_sectors %>% filter(!grepl('s0', code))

for (i in list_com[,"code"]){

  baseline_ch2 <- mutate(baseline_ch2,
                      
                      
   !!paste0("dsd_",i) := get(paste0("dsd_",i))[which(year ==  baseyear)]*0.8^(year-baseyear),
   !!paste0("dsm_",i) := get(paste0("dsm_",i))[which(year ==  baseyear)]*0.8^(year-baseyear)
                  ) 
}


#(2) Using interpolation of missing values


#(3) From another database with interpolation directly
baseline_ch3 <- selection

baseline_ch3 <- load_excel_calibration(excel_sheet = "configuration/scenarii_calib/scenarii_inputs.xlsx",
                                       sheet_to_load = "baseline",
                                       stop_if_calib_fail = FALSE,
                                       keep_baseyear_calib_data = TRUE) %>% 
  filter(year %in% c(firstyear:lastyear)) 



## Merge all part of the baseline scenario
baseline_ch <- merge(baseline_ch1, baseline_ch2) %>% merge(baseline_ch3)
