# INF564-Projet

This repository contains our submission for the project of the course INF564 - Compilation. 

A simple make command suffices to build the project. To run the tests, run the following command:
```console
cd build && ./run -all "../minic.exe"
```

The compiler we built takes as entry an abstract syntax tree (built from the syntactic analyzer given at the beginning of the project) to build x86-64 code. It follows the directions given for the project, namely the 5 following steps: instruction selection, RTL code, ERTL code, LTL code, and finally x86-64 code.
