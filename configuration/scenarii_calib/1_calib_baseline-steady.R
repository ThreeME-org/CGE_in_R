# Baseline hypotheses calibrations

## Load calibration for range baseyear:lastyear
calib <- OGcalib %>% filter(year %in% c(firstyear:lastyear)) 


## Define baseline steady state (no change in exogenous variables) 
baseline_ch <- calib %>% select(year)
