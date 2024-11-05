' ============================================================================
' This file defines the configuration options
'
' ============================================================================

' Define model name
%modelname = "a_3ME"
' Set "u0, u1,... " for user options; "d" diagnostic option; something else for default option
%solveopt = "u0"
' Set the threshold under which the value is rounded to zero.
!round0 = 1.0E-10
' Set frequency ("a" : annual; "q" quarterly)
%freq = "a"

' Set compiler option
%compiler = "exec" 
