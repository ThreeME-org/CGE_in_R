' ============================================================================
' Series of subroutines used to run the model

' Additional user defined run subroutines in the file "run_extra.prg"
' Here only the basic run subroutine!
' ============================================================================
' ============================================================================
' +++++++++++++++++++
' Subroutine "Run"
' +++++++++++++++++++
' Called from Eviews by the progam main
' Performs a complete model run:
' - loads the calibration of the variables
' - loads the specification of the model
' - run scenario(s)

subroutine run(string %recompile_model, string %warning, string %scenario)

%wfname = ".\..\..\results\eviews\" + %modelname + "_" + %iso3

if %recompile_model="TRUE"  then

	' Load calibration
	wfcreate(wf=%wfname, page=%modelname) {%freq} {%firstyear} {%lastyear}
	' Splits the loading in 2 files if necessary: 
	'         Some series are not loaded by Eviews when more than (about) 50 000 variables or file gigger than 14 MB
	
	if @fileexist("..\compiler\calib1.csv") = 1 then
 		statusline Loading calibration: File 1
  		import .\..\compiler\calib1.csv @smpl
  		statusline Loading calibration: File 2
  		import .\..\compiler\calib2.csv @smpl 
		else
  		statusline Loading calibration: calib.csv
  		import .\..\compiler\calib.csv @smpl
	endif
	
  	' Create model
  	statusline Loading specification
  	model {%modelname}
  	exec(c, q) .\..\compiler\model.prg
	
  	' Importing baseline scenario  
  	import(mode=u) .\..\..\configuration\scenarii_calib\calib_baseline.csv @smpl

  	' Save workfile before simulation
     wfsave {%wfname}
	
  	' Checking that equations are balanced at baseyear (add factors = 0)
  	if %warning = "TRUE" then 
    		call checkaddfactor(%modelname,{%tolerance_calib_check})
  	endif


else

	' ## Load the workfile of an existing model
  	wfopen {%wfname}    ' Load workfile if already created (the workfile should be in ThreeME_V3\results\eviews\)
	
endif


  ' Simulating baseline scenario
  statusline Solving baseline

  smpl {%baseyear} @last	
  call solvemodel(%solveopt) 

  ' Save exogenous variables for the baseline (_0)
  %exo = {%modelname}.@exoglist
  for %series {%exo}
       series {%series}_0 = {%series}
  next

  ' Solve scenario
  statusline Solving scenario {%scenario}
  {%modelname}.scenario(n, a=2) {%scenario}

  ' Importing shock scenario 
  smpl {%firstyear} @last	
  import(mode=u) .\..\..\configuration\scenarii_calib\calib_shock_{%scenario}.csv  @smpl

  smpl {%baseyear} @last	
  call solvemodel(%solveopt) 

  ' Save exogenous variables for the shock  (_2) 
  %exo = {%modelname}.@exoglist
  for %series {%exo}
       series {%series}_2 = {%series}
  next

  ' Save all results to csv file
  delete(noerr) all_vars_table
  group all_vars *_0 *_2
  freeze(all_vars_table) all_vars
  %pathcsv= @linepath + "..\..\data\temp\csv\" + %scenario + ".csv"
  all_vars_table.save(t=csv) %pathcsv


' Saving workfile with simulation
if %save_files_res="TRUE"  then
	%wfname = ".\..\..\results\eviews\"+%scenario+ "_" + %iso3
	wfsave {%wfname}
endif

endsub

'************************************************************************************************
'************************************************************************************************
'************************************************************************************************
'*********** RUN OLD COMPILER SUBROUTINE ****************************************
'************************************************************************************************
'************************************************************************************************
'************************************************************************************************

subroutine run_oldcompiler(string %recompile_model, string %warning, string %scenario)

'call R_lists
'call EViews_lists

'************************************************
'*********** DEFINE THE MODEL *******************
'************************************************
%wfname = ".\..\..\results\eviews\" + %modelname + "_" + %iso3
if %recompile_model="FALSE"  then
' ## Load the workfile of an existing model
  if %warning = "TRUE"  then
  shell(h) rundll32 user32.dll,MessageBeep 
  %name = %modelname+"_"+%iso3
  %namePrompt = "Enter file name"
  !answer = @uidialog("Caption", "Open an exiting workfile", "Edit", %name, %namePrompt, 64)
  %wfname = ".\..\..\results\eviews\"+%name
      if !answer = 0 then
        wfopen {%wfname}    ' Load workfile if already created (the workfile should be in ThreeME_V3\results\)
      else
        stop
      endif
  else
  wfopen {%wfname}    ' Load workfile if already created (the workfile should be in ThreeME_V3\results\eviews\)
  endif
else
' ## Create a new model 
 
  ' Create the Workfile
  wfcreate(wf=%wfname, page=%modelname) {%freq} {%firstyear} {%lastyear}
  'Give a name to the Model
  model {%modelname}
  
  ' Export all variables to a csv file (this file is needed to execute the external compiler)
  call export_all_to_csv
  ' Create the series using the dependencies graph (subroutine "load_series")
  statusline "Compiling the calibration of the model's variables... Please wait as it might take a few minutes..."

  call load_series("data_files")

  ' Export all variables to a csv file (used by the external compiler)
  call export_all_to_csv
  ' Load the model specification from the model/ folder
  statusline "Compiling the equations of the model... Please wait as it might take a few minutes..."

  call load_model("model_files.mdl")

' Save the workfile before running simulation
if %recompile_model = "TRUE" then

    if %warning = "TRUE"  then
      shell(h) rundll32 user32.dll,MessageBeep 
      %name = %modelname+"_"+%iso3
      %namePrompt = "Enter file name"
      !answer = @uidialog("Caption", "Save workfile before simulation?", "Edit", %name, %namePrompt, 64)
      %wfname = ".\..\..\results\eviews\"+%name
      if !answer = 0 then
         wfsave {%wfname}
      endif
    endif
endif
  ' Clean up results folder
  %cmd = @left(@linepath, 2) + " & cd " + @addquotes(@linepath) + " & del /Q ..\..\results\eviews\*.txt"
  shell(h) {%cmd}
endif

' Checking that equations are balanced at baseyear (add factors = 0)
  if %recompile_model = "TRUE" and %warning = "TRUE" then 
    call checkaddfactor(%modelname,{%tolerance_calib_check})
  endif
'************************************************
'*********** SOLVE SCENARIOS ********************
'************************************************
' ***************************************
' Call here the subroutine you want to use to solve the shock

' ********************************  Simulate baseline scenario
statusline Simulating scenario baseline. 
smpl {%baseyear} @last

' Importing baseline scenario 
import(mode=u) .\..\..\configuration\scenarii_calib\calib_baseline.csv @smpl

call solvemodel(%solveopt)

' Save exogenous variables for the baseline (_0)
%exo = {%modelname}.@exoglist
for %series {%exo}
     series {%series}_0 = {%series}
next

' *********************************  Simulate shock scenario
statusline Simulating scenario %scenario. 
' Create a new scenario that can be compared with the baseline
{%modelname}.scenario(n, a=2) {%scenario}

'smpl 2021 @last
''G = G + 1
'G = G + 0.01*@elem(Y,%baseyear)


smpl {%baseyear} @last
' Importing shock scenario 
import(mode=u) .\..\..\configuration\scenarii_calib\calib_shock_{%scenario}.csv  @smpl

'call load_excel("Test_Exiobase", "scenarii", %scenario)
'call interpolate("RCO2TAX_VOL")

call solvemodel(%solveopt) 
' Save exogenous variables for the shock  (_2) 
%exo = {%modelname}.@exoglist
for %series {%exo}
     series {%series}_2 = {%series}
next

' *******************
' Save all results to csv file
delete(noerr) all_vars_table
group all_vars *_0 *_2
freeze(all_vars_table) all_vars
%pathcsv= @linepath + "..\..\data\temp\csv\" + %scenario + ".csv"
all_vars_table.save(t=csv) %pathcsv

' **********************
' Saving workfile with simulation
if %warning = "TRUE"  then
  shell(h) rundll32 user32.dll,MessageBeep
  %name = %scenario
  %namePrompt = "Enter file name"
  scalar answer = @uidialog("Caption", "Save workfile result", "Edit", %name, %namePrompt, 64)
  %wfname = ".\..\..\results\eviews\"+%name
  if answer = 0 then
       wfsave {%wfname}
  endif

else

%wfname = ".\..\..\results\eviews\"+%scenario
wfsave {%wfname}

endif
endsub


