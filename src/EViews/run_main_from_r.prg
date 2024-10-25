' Configuration
%iso3 = "fra"
%scenario = "expg1"

%firstyear = "2016"
%baseyear = "2019"
%lastyear = "2050"

%warning = "FALSE"
%compil = "dynamo"
%recompile_model = "FALSE"
%save_files_res = "TRUE"


%tolerance_calib_check = "0.001"

%path_eviews_default = "C:/Users/Administrator/Documents/GitHub/ThreeME_V4/src/EViews/"

cd %path_eviews_default
' Run main:  c = run program file without display the program file window; q = quiet
run(1,c,q) main


