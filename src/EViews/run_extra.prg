' ============================================================================
' ============================================================================
' ==============    CHECK ADDFACTOR  =========================================
' ============================================================================

' This subroutine check if the model is correctly calibrated at the baseyear.
subroutine checkaddfactor(string %model,scalar !threshold)
statusline Creating Add factors and checking if they are different from 0 at baseyear.
' Put add factors to all equations
smpl {%baseyear} {%baseyear}
{%modelname}.addassign @all
' Set add factor values so that the equation has no residual when evaluated at actuals
{%modelname}.addinit(v=n) @all
' Make the list of all endogenous variables
%endo = {%modelname}.@endoglist

' Initialisation of the list of imballanced equations
%imbalance = ""
' Checking and listing the equations with non zero addfactors
for %var {%endo} 
  if @abs(@elem({%var}_a, %baseyear)) > !threshold then
    %imbalance = %imbalance +" "+%var+"_a"
  endif
next 

' Result messages
shell(h) rundll32 user32.dll,MessageBeep
if @str(@wcount(%imbalance)) > 0 then
  scalar answer = @uiprompt("WARNING: NON ZERO ADD FACTORS AT BASEYEAR: "+@str(@wcount(%imbalance))+" equations have a calibration imballance higher than "+@str(!threshold)+". Would you like see them and abort?", "YN")
  if answer = 1 then
      smpl {%baseyear} {%baseyear}
      show {%imbalance}
      stop
  endif
else
 @uiprompt("CHECK ADD FACTORS OK !")
endif

smpl @all
endsub

