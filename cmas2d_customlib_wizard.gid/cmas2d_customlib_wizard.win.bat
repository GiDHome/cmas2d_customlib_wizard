rem OutputFile: %2\%1.boh
rem ErrorFile: %2\%1.err
del %2\%1.boh
del %2\%1.post.res
del %2\%1.post.dat
del %2\%1.err
%3\exec\cmas2d-windows.exe %2\%1
