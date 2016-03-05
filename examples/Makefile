CC=gcc
CFLAGS=-g -Wall
SRC=$(wildcard *.c)
BIN=$(SRC:.c=)

all: $(BIN)

token-sh: token-sh.c
	$(CC) $(CFLAGS)  token-sh.c -o token-sh -lreadline


clean:
	rm -f $(BIN)  *~
