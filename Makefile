TARGET = iChabber

VERSION := r`unset LC_ALL ; unset LANG ; svn info | grep Revision | cut -f2 -d':' | sed 's/ //g'`

LANGUAGES=$(wildcard *.lproj)

CC = arm-apple-darwin-gcc

LD = $(CC)

CFLAGS	= -DHAVE_OPENSSL -DDEBUG=1 -Wall -O2

LDFLAGS	= -ObjC -lobjc \
	-framework CoreFoundation \
	-framework Foundation \
	-framework UIKit \
	-framework LayerKit \
	-framework CoreGraphics \
	-framework GraphicsServices \
	-framework Celestial \
	-framework CoreTelephony \
	-framework Message \
	-framework IOKit \
	-framework AppSupport \
	-lssl -lcrypto
	
LDFLAGS_FRAMEWORKSDIR=-F/opt/iphone-sdk/share/heavenly/System/Library/

all:	$(TARGET)

genlocalestr:
	for i in $(LANGUAGES); do \
	    genstrings -aq -o $$i/ *.m ;\
	done

OBJS =  lib/connwrap/connwrap.o \
	lib/server.o \
	lib/socket.o \
	lib/utf8.o \
	lib/utils.o \
	lib/conf.o

APPOBJS = main.o \
	  iCabberApp.o \
	  iCabberView.o \
	  MyPrefs.o \
	  UserView.o \
	  NewMessage.o \
	  Buddy.o \
	  Notifications.o \
	  EyeCandy.o \
	  BuddyAction.o \
	  IconSet.o \
	  BuddyCell.o \
	  resolveHostname.o \
	  NSLogX.o

$(TARGET):  version.h $(APPOBJS) $(OBJS)
	$(LD) $(LDFLAGS_FRAMEWORKSDIR) $(LDFLAGS) -o $@ $^

version.h:
	echo "#define APP_VERSION \"$(VERSION)\"" > $@

%.o:	%.m
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f $(TARGET) $(OBJS) $(APPOBJS) $(TARGET)-$(VERSION).zip version.h
		rm -rf $(TARGET).app

upload: $(TARGET)
	scp $(TARGET) root@sashz-iphone:/Applications/iChabber.app/

package: $(TARGET)
	rm -rf $(TARGET).app
	mkdir -p $(TARGET).app
	cp $(TARGET) $(TARGET).app/$(TARGET)
	cp Info.plist $(TARGET).app/Info.plist
	cp icons/*.png $(TARGET).app/
	cp sounds/*.aiff $(TARGET).app/
	for i in $(LANGUAGES); do \
	    mkdir -p $(TARGET).app/$$i; \
	    cp $$i/Localizable.strings $(TARGET).app/$$i; \
	done

dist: package
	zip -9r $(TARGET)-$(VERSION).zip $(TARGET).app/
