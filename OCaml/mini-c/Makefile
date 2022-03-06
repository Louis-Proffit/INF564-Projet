
all:minic.exe

test: minic.exe
	./minic.exe --debug --interp-ltl test.c

minic.exe:
	dune build minic.exe

clean:
	dune clean

.PHONY: clean minic.exe


