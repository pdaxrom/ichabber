TARGET = iLocator

LANGUAGES=$(wildcard *.lproj)

CC = arm-apple-darwin-gcc

LD = $(CC)

CFLAGS	= -Wall

LDFLAGS	= -ObjC -lobjc \
	-framework CoreFoundation \
	-framework Foundation \
	-framework UIKit \
	-framework LayerKit \
	-framework CoreGraphics \
	-framework GraphicsServices \
	-framework CoreTelephony

all:	$(TARGET)

genlocalestr:
	for i in $(LANGUAGES); do \
	    genstrings -aq -o $$i/ *.m ;\
	done

APPOBJS = \
	iLocator.o \
	iLocatorApp.o \
	LLData.o

$(TARGET): $(APPOBJS)
	$(LD) $(LDFLAGS_FRAMEWORKSDIR) $(LDFLAGS) -o $@ $^

%.o:	%.m
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f $(TARGET) $(OBJS) $(APPOBJS) $(TARGET)-$(VERSION).zip version.h
