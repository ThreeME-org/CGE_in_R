' ============================================================================
' ============================================================================
' ==============    DEFINE FIT TARGET OBJECTIVES  ===============================
' ============================================================================

' ********************************************************************************** '
' ********************************************************************************** '
' ********************************************************************************** '

subroutine fittarget_obj(string %objective)

' ******************************************* '
' The objective is GDP

if %objective = "gdp" then

    group controls GDP_fit
    group targets GDP
    group trajectories GDP_trendbis

    smpl {%baseyear} @last
    {%modelname}.mcontrol controls targets trajectories
    string listcontrol =  listcontrol + " GDP_fit"	
endif

' ******************************************* '
' The objective is the agregate energy consumption of sectors
if %objective = "CI_TOE_non_nrj_sect" then

logfittarget.append ""
logfittarget.append ### Start iterations for objective %objective

	scalar itersolution = 0.0000001
	while itersolution > 0
		scalar itersolution = 0

    %list_sec = ""
    for %s sagr sfor sfoo
	
		smpl 2030 2030
		series F_E_{%s} = 1.3 * @elem(F_E_{%s}, {%baseyear})
	     smpl 2050 2050
     		series F_E_{%s} = 2.40 * @elem(F_E_{%s}, {%baseyear}) 

		call fittarget("GR_PROG_fit_E_"+%s, "constant", "F_E_"+%s, "F_E_"+%s+"_2",%baseyear ,"2030", 0.1)
      	scalar itersolution = itersolution +  iteration

      	call fittarget("GR_PROG_fit_E_"+%s, "constant", "F_E_"+%s, "F_E_"+%s+"_2","2030","2050", 0.1)
		scalar itersolution = itersolution +  iteration

	next 

	%statusline = "Total iterations for objective "+ %objective+"  "+ @str(itersolution)
	statusline %statusline
	logfittarget.append %statusline

  scalar itersolution_all = itersolution_all + itersolution
	wend

%statusline = "### Global solution found for objective "+ %objective+" !!!!"
statusline %statusline
logfittarget.append %statusline

for %s sagr sfor sfoo
    string listcontrol =  listcontrol + " GR_PROG_fit_E_"+%s
next

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
%list_sec = "sagr sfor sfoo sveh sgla sche spla smet sigo scgo scon srai sroa swat sair spri sfin spub smin sfos seoi sega sewi seso sehy seot"
%list_com = "cagr cfor cfoo cveh cgla cche cpla cmet cigo ccgo ccon crai croa cwat cair cpri cfin cpub cmin ccoa cfut cgas cele"

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
  'call fittarget_obj("gdp")

' 2. Fit energy final consumption for non energy sectors
  call fittarget_obj("CI_TOE_non_nrj_sect")

smpl {%baseyear} @last
group control_var{!j} {listcontrol}
show control_var{!j} 

%statusline = "**** TOTAL ITERATIONS FOR ALL OBJECTIVES : "+ @str(itersolution_all)
statusline %statusline
logfittarget.append %statusline

next

' Manuel show: 
' show GDP_CONT


