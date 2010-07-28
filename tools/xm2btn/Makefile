INSTALL = install
CFLAGS = -Wall -g
LFLAGS =
OBJS = xm2btn.o xm.o main.o

prefix = /usr/local
datarootdir = $(prefix)/share
datadir = $(datarootdir)
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
infodir = $(datarootdir)/info
mandir = $(datarootdir)/man
docbookxsldir = /sw/share/xml/xsl/docbook-xsl

xm2btn: $(OBJS)
	$(CC) $(LFLAGS) $(OBJS) -o xm2btn

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

install: xm2btn
	$(INSTALL) -m 0755 xm2btn $(bindir)

clean:
	rm -f $(OBJS) xm2btn xm2btn.exe

.PHONY: clean install
