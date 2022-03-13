
all:minic.exe

test: minic.exe
	./minic.exe test.c

minic.exe:
	dune build minic.exe

clean:
	dune clean

.PHONY: clean minic.exe


