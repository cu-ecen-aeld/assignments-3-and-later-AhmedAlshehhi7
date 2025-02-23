# Use CROSS_COMPILE if defined; otherwise, default to native gcc.
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Werror

.PHONY: all clean

# Default target: build the writer application.
all: finder-app/writer

# Build the writer application from writer.c
finder-app/writer: finder-app/writer.c
	$(CC) $(CFLAGS) finder-app/writer.c -o finder-app/writer

# Clean target: remove the writer executable and any object files.
clean:
	rm -f finder-app/writer *.o
