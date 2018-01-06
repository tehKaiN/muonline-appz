# Wedit Makefile for project muKonfig
SRCDIR=d:\prg\__c\muconfig
CFLAGS=-I"D:\kompilatory\lcc\include"  -O  -p6 -unused
CC=$(LCCROOT)\bin\lcc.exe
LINKER=$(LCCROOT)\bin\lcclnk.exe
OBJS=\
	main.res \
	mukonfig.obj

LIBS=
EXE=mukonfig.exe

$(EXE):	$(OBJS) Makefile
	$(LINKER)  -s -subsystem windows -o $(SRCDIR)\lcc\mukonfig.exe $(OBJS) $(LIBS)

# Build main.res
MAIN_RC=\

main.res:	$(MAIN_RC) $(SRCDIR)\main.rc
	$(LCCROOT)\bin\lrc.exe -I$(SRCDIR) -I"D:\kompilatory\lcc\include"  $(SRCDIR)\main.rc

# Build mukonfig.c
MUKONFIG_C=\
	D:\kompilatory\lcc\include\windows.h\
	D:\kompilatory\lcc\include\stdlib.h\
	D:\kompilatory\lcc\include\stddef.h\
	D:\kompilatory\lcc\include\_syslist.h\
	D:\kompilatory\lcc\include\safelib.h\
	D:\kompilatory\lcc\include\string.h\
	D:\kompilatory\lcc\include\safelib.h\
	D:\kompilatory\lcc\include\win.h\
	D:\kompilatory\lcc\include\limits.h\
	D:\kompilatory\lcc\include\stdarg.h\
	D:\kompilatory\lcc\include\ctype.h\
	D:\kompilatory\lcc\include\basetsd.h\

mukonfig.obj: $(MUKONFIG_C) $(SRCDIR)\mukonfig.c
	$(CC) -c $(CFLAGS) $(SRCDIR)\mukonfig.c

link:
	$(LINKER)  -s -subsystem windows -o $(SRCDIR)\lcc\mukonfig.exe $(OBJS) $(LIBS)

clean:
	del $(OBJS) mukonfig.exe
