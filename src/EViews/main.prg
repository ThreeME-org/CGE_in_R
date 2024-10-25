' IMPORTANT WARNING!! You may need to RUN E-views as administrator.
'run(1,c,q) main ' Run a program. c : run program file without display the program file window. v / q : verbose / quiet; ver4 / ver5 : Execute program in previous version script.


' ***************
' Configuration
include .\configuration.prg


' **********
' Includes suroutines
include .\load_data
include .\solve
include .\run
include .\run_extra
include .\load_compiler.prg

' ***********
' Run model simulation
if %compil = "python"  then

	call run_oldcompiler(%recompile_model, %warning, %scenario)

  else

 	call run(%recompile_model, %warning, %scenario) 
 
endif

smpl %baseyear @last

' Close all object and exit Eviews
close @all
exit


