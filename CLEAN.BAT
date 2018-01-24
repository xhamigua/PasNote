@del /s /q /f /A  *.dcu *.log *.identcache *.local *.hpp *.xml *.~* ~*.* *.ddp *~ .\project\*obj 
rd  -r -q __history\ out\
md bin\dcu
REM del *.cfg /s
REM del *.res /s 
REM del *.dof /s
REM del bin\*.dll /s /q
REM del bin\*.exe /s /q
