' ============================================================================
' ============================================================================
' ==============    FIT TARGET       =========================================
' ============================================================================

' This subroutine allows for the model to reach a target at a given year. By interpoling a control variable between an initial and last year. Its arguments are:  
' %var_cont : Exogenous control variable used to reach the target
' %inter : interpolation method used to interpolate the control variable between the initial and last value. "constant" : the control variable is constant, otherwise (log)-Catmull-Rom spline --> see subroutine interpolate_period
' %var_target : target that the endogenous variable should reach at the last year
' %var_traj : endogenous variable that should follow the target. It should be the result variable that with the relevant scenario number (e.g. with _0 for baseline) 
' %firstyear : fisrt year
' %lastyear : last year
' !convcrit : Convergence criterion

subroutine fittarget(string %var_cont, string %inter, string %var_target, string %var_traj, string %firstyear, string %lastyear, scalar !convcrit)

%statusline = "Start fittarget for control variable "+ %var_cont+", option "+ %inter + ". Target variable "+ %var_target+ " should be matched by trajectory variable "+%var_traj+" in " + %lastyear+"."
statusline %statusline
logfittarget.append %statusline



' Initializations
smpl {%baseyear} {%lastyear}
{%modelname}.solve(o=b, g=10, m=5500, c=1e-8, z=1e-8,j=a,i=p,v=t)

scalar crit = @elem({%var_target}, %lastyear) - @elem({%var_traj}, %lastyear)
scalar cont = @elem({%var_cont}, %lastyear)
scalar dcrit_dcont =  na
!smplperiods = {%lastyear} - {%firstyear}

scalar iteration = 0
while @abs(crit) > !convcrit

  ' Correction of the control variable
  smpl {%lastyear} {%lastyear}
  if iteration = 0 then  	 
  	{%var_cont} = {%var_cont} + 0.001	
  else
  	{%var_cont} = {%var_cont} - crit/dcrit_dcont
  endif

  if !smplperiods > 0 then  

    smpl {%firstyear}+1 {%lastyear}-1 
    If %inter = "constant" then
    	{%var_cont} = @elem({%var_cont}, %lastyear)
    else
    	{%var_cont} = na
    	call interpolate_period(%var_cont, %firstyear, %lastyear)
    endif
 
  endif

  smpl {%baseyear} {%lastyear}
  {%modelname}.solve(o=b, g=10, m=5500, c=1e-8, z=1e-8,j=a,i=p,v=t)

  ' Calculation of the first derivative of the criterium with respect to the control variable
  scalar dcrit   = @elem({%var_target}, %lastyear) - @elem({%var_traj}, %lastyear) - crit
  scalar dcont = @elem({%var_cont}, %lastyear) - cont
  scalar dcrit_dcont =  dcrit / dcont 

  ' Calculation of the new criterium and the new control variable
  scalar crit = @elem({%var_target}, %lastyear) - @elem({%var_traj}, %lastyear)
  scalar cont = @elem({%var_cont}, %lastyear)

  ' Inform log file and statusline
  %statusline = "Iteration "+ @str(iteration)+": Criterium = "+ @str(crit)+"; dcrit/dcont =   " + @str(dcrit_dcont)+ "; Control = "+ @str(cont)
  statusline %statusline
  logfittarget.append %statusline



scalar iteration = iteration + 1
wend

' Inform final result in log file and statusline
if iteration = 0 then
	%statusline = " !! Solution found in "+ @str(iteration)+" iteration !!! Criterium = "+ @str(crit)+"; dcrit/dcont =   " + @str(dcrit_dcont)+ "; Control = "+ @str(cont)
else
	%statusline = "  !!!! SOLUTION FOUND !!!!" 
endif

statusline %statusline
logfittarget.append %statusline

endsub

' ********************************************************************************** '
' ********************************************************************************** '
' ********************************************************************************** '

