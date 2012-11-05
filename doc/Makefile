#
#	Makefile for manued
#		Copyright 1998-2012 (C) Hitoshi Yamauchi
#
#
MAKEINFO = makeinfo
TEXI2DVI = texi2dvi
MANUEDTEXI = manued.texi

#
# do not change below this line
#
all	: manued.info manued.dvi

# info
manued.info	: $(MANUEDTEXI)
	$(MAKEINFO) $(MANUEDTEXI)

# dvi
manued.dvi	: $(MANUEDTEXI)
	$(TEXI2DVI) $(MANUEDTEXI)


clean::
	$(RM) *~ *.cp *.fn *.ky *.pg *.tp *.vr *.dvi *.aux *.log *.toc

