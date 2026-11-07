# Example app for az0x-firmware-kit. Replace it with your own by setting
# BR2_PACKAGE_AZ0X_APP_SOURCE_DIR. The only contract: "make install
# DESTDIR=..." must install an executable /opt/app/start.

CC ?= cc
CFLAGS ?= -O2
CFLAGS += -Wall -Wextra

all: hello

hello: hello.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $< -lasound

install: hello
	install -D -m 0755 hello $(DESTDIR)/opt/app/hello
	install -D -m 0755 start $(DESTDIR)/opt/app/start

clean:
	rm -f hello

.PHONY: all install clean
