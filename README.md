Description
	Ds1072ca plotting script. Plots exactly what you see in scope. Needs
channel parameters and csv files. Creates gnuplot script in /tmp directory.
generates pdf files and copies to current directory.

How to Use
       make script executable
       execute script, pass current path as argument
       done. files plotted to current directory

example
	cd ~/osi_files
	ls
		NewFile0.csv NewFile1.csv
       	./osiplot.sh $(pwd)
		...
	ls
		NewFile0.csv NewFile1.csv NewFile0.pdf

Why
	Oscilloscope itself can take screenshot which has a background color
black. With this script printer friendly plot generated. With csv files more
precise result taken. But for fast result this script generates what you see
in scope.