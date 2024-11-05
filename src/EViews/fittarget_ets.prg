' ============================================================================
' ============================================================================
' ==============    DEFINE FIT TARGET OBJECTIVES  ===============================
' ============================================================================

' ********************************************************************************** '
' ********************************************************************************** '
' ********************************************************************************** '

subroutine fittarget_obj(string %objective)

' ******************************************* '
' The objective is the level of CO2 emissions

if %objective = "CO2_emissions" then

logfittarget.append ""
logfittarget.append ### Start iterations for objective %objective

  smpl 2030 2030
  series EMS_CI = 0.9 * @elem(EMS_CI, {%baseyear})
  smpl 2050 2050
  series EMS_CI = 0.8 * @elem(EMS_CI, {%baseyear})


  scalar itersolution = 0.0000001
  while itersolution > 0
    scalar itersolution = 0

    call fittarget("PETS_VOL", "interp", "EMS_CI", "EMS_CI_2","2020","2030",0.1)
    scalar itersolution = itersolution +  iteration

  %statusline = "Total iterations for objective "+ %objective+" 2030: "+ @str(itersolution)
  statusline %statusline
  logfittarget.append %statusline

  scalar itersolution_all = itersolution_all + itersolution
  wend

  ' Recalculate starting value if solving error in 2031
  ' smpl 2031 2050
  ' series PETS = @elem(PETS, 2030)

  scalar itersolution = 0.0000001
  while itersolution > 0
    scalar itersolution = 0

    call fittarget("PETS_VOL", "interp", "EMS_CI", "EMS_CI_2","2030","2050",0.1)
    scalar itersolution = itersolution +  iteration

  %statusline = "Total iterations for objective "+ %objective+" 2050: "+ @str(itersolution)
  statusline %statusline
  logfittarget.append %statusline

  scalar itersolution_all = itersolution_all + itersolution
  wend


%statusline = "### Global solution found for objective "+ %objective+" !!!!"
statusline %statusline
logfittarget.append %statusline

string listcontrol =  listcontrol + " PETS_VOL"

endif


endsub

' ============================================================================
' ============================================================================
' ==============    RUN FIT TARGET OBJECTIVES       ================================
' ============================================================================
' Run as stand alone

' Subroutines needed
include .\fittarget.prg
include .\configuration.prg
include .\load_data
include .\run_extra
include .\solve

' MANUAL CONFIG: Use same configuration as mdl files
%baseyear = "2019"
'%list_sec = "sagr sfor sfoo sveh sgla sche spla smet sigo scgo scon srai sroa swat sair spri sfin spub smin sfos seoi sega sewi seso sehy seot"
'%list_com = "cagr cfor cfoo cveh cgla cche cpla cmet cigo ccgo ccon crai croa cwat cair cpri cfin cpub cmin ccoa cfut cgas cele"

' Create log file
if @isobject("logfittarget")=1 then
  delete logfittarget
endif
text logfittarget
show logfittarget


call solvemodel(%solveopt) 

' Loop to (eventually) run several round of fit (can be used to check stability
for !j=1 to 1

' Initialization of the number of global iteration
scalar itersolution_all = 0 

' Initialize list of control variables
string listcontrol = ""

  %statusline = "##### START ROUND : "+ @str(!j) +  " #########"
  statusline %statusline
  logfittarget.append %statusline

' 1. Fit the target for GDP
  call fittarget_obj("CO2_emissions")

smpl {%baseyear} @last
group control_var{!j} {listcontrol}
show control_var{!j} 

%statusline = "**** TOTAL ITERATIONS FOR ALL OBJECTIVES : "+ @str(itersolution_all)
statusline %statusline
logfittarget.append %statusline

next

' Manuel show: 
' show EMS_CI


