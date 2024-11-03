##################################################################################
####### THREEME USER CONFIGURATION
##################################################################################
## Please check sections 1 to 3 before running ThreeME

#########################################
# 1. Basic Parameters
#########################################


iso3 = "FRA"                   
classification = "c0_s0" 
model_folder = "training"
project_name = "session3"


scenario_baseline = "baseline-steady" # Maybe modified if the baseline needs to integrate some user-specified trajectories of exogenous variables.  All scenarii files are  located in configuration/scenarii_calib
scenario = c("progl") |> 
  set_names(c("Increase government spending of 1% of GDP"))
## Input the base year used for the calibration
baseyear = 2019
## Set the end of the sample
lastyear = 2050
## Set the year of the shock
shockyear = 2021
## Set the highest lag used in the modelxs
max_lags = 3
## Calculate first year of simulation 
firstyear = baseyear - max_lags

automated_shocks = FALSE # Set to TRUE if you want to use automated shocks, that will read one unique shock scenario file that can run different calibrations according to the scenario name

## Specify here the variables to keep in the data output, leave empty to export all variables.

# variables_to_keep = c("RCO2TAX_VOL","GDP","LF", "CH", "I", "X", "M", "PVA", "PCH", "PY", "PX", "PM", "DISPINC_AT_VAL", "W", "RSAV_H_VAL","F_L", "RBAL_TRADE_VAL", "RBAL_G_TOT_VAL", "MARKUP", "UNR","EMS","RSAV_G_VAL","RBAL_G_PRIM_VAL","BAL_TRADE","C_L","VA")
variables_to_keep = c() ## leave empty to keep all variables. 


#########################################
# 2. Files lists for the model
#########################################

## Lists files (warning: if more than one, place "lists.mdl" last)
lists_files = c(
  # str_c("R_lists_", iso3,"_",classification, ".mdl"),             # ALL VERSIONS
  "lists.mdl"                                                     # ALL VERSIONS
)

calib_files <- c(lists_files,
                 "03.1-calib.mdl",     
                 
                 "ENDOFLINE.mdl"       # ALL VERSIONS: empty file
                 
)

# Model files 
model_files = c(lists_files,
                "03.1-eq_keynes_basic.mdl",        
                
                
                "ENDOFLINE.mdl"        # ALL VERSIONS: empty file
                
)

#########################################
# 3. Solver configuration
#########################################

Rsolver = TRUE    # If TRUE, will try to Use R solver if possible; If FALSE EViews will be used
warning = FALSE     # If TRUE, will provide solver warning messages
tolerance_calib_check = 10^-3
skip_compiler = FALSE # Set to TRUE to skip the compiler part. However, you'll need to ensure to have the correct model.prg and calib.csv files in the src/compiler folder 
recompile_model = TRUE # If FALSE, the model will be sourced from its last saved version. In the case of multiple scenarii, the model is never recompiled between shocks  
output_saved = c() ## use c("com","sec","sec_com") to save all three types of reaggregated database

#################
## 3.A EViews
#################
## Set manually the default location of EViews.exe
path_eviews_exe = "C:/Program Files/EViews 10/EViews10_x64.exe"

eviews_timeout = 0       # Define the maximum number of second R waits for the E-views simulation # (0 = no time out)

#################
## 3.B R solver
#################

rcpp_option = FALSE 

### If superlu is installed, switch to TRUE, otherwise FALSE
use.superlu = TRUE 
### Specify here if there is special configuration necessary to  use superlu
if(use.superlu == TRUE){ 
  Sys.setenv("CPATH"="/opt/homebrew/include")
  Sys.setenv("LIBRARY_PATH"="/opt/homebrew/lib")
  Sys.setenv("PKG_LIBS"="-lsuperlu")
}


