# IRAF definitions for the UNIX/csh user.  The additional variables iraf$ and
# home$ should be defined in the user's .login file.

#setenv	MACH	`mach`
#setenv	MACH	vax

# Domain/OS:  This ISP stuff is NECESSARY for network logins (e.g. rsh) that
# read the IRAF .cshrc file and "source" this file.  Any other *reference*
# at all to $ISP causes an abort if it happens not to be defined!
#if ("$ISP" == "") then
#    set ISP="m68k"
#    set MACH="m68k"
#else
#    set MACH=`echo $ISP`
#endif
#set ISP="m68k"
#set MACH="m68k"

setenv	hostid	unix
setenv	host	${iraf}unix/
setenv	hlib	${iraf}unix/hlib/
setenv	hbin	${iraf}unix/bin.$MACH/
setenv	tmp	/tmp/

# HSI cc, f77, and xc compile/link flags [MACHDEP].
switch ($MACH)
case i386:
case sparc:
	setenv	HSI_CF		"-O"
	setenv	HSI_FF		"-O"
	setenv	HSI_XF		"-O -z"
	setenv	USE_RANLIB	"yes"
	breaksw
case mc68020:
	setenv	HSI_CF		"-O -fsoft"
	setenv	HSI_FF		"-O -fsoft"
	setenv	HSI_XF		"-O -/fsoft -z"
	setenv	USE_RANLIB	"yes"
	breaksw
case m68k:
	setenv	HSI_CF		"-W0,-opt,2,-nbss,-db -A nansi"
	setenv	HSI_FF		"-W0,-opt,2,-save,-db"
	setenv	HSI_XF		"-/W0,-opt,2,-save,-db"
	setenv	USE_RANLIB	"no"
	breaksw
case a88k:
	setenv	HSI_CF	"-W0,-opt,2,-nbss,-dbs,-cpu,a88k -A nansi -DA88K"
	setenv	HSI_FF		"-W0,-opt,2,-save,-dbs,-cpu,a88k"
	setenv	HSI_XF		"-/W0,-opt,2,-save,-dbs,-cpu,a88k"
	setenv	USE_RANLIB	"no"
	breaksw
default:
	setenv	HSI_CF		"-O"
	setenv	HSI_FF		"-O"
	setenv	HSI_XF		"-O"
	setenv	USE_RANLIB	"yes"
	breaksw
endsw

# The following determines whether or not the VOS is used for filename mapping.
if (-f ${iraf}lib/libsys.a) then
	setenv	HSI_LIBS\
    "${hlib}libboot.a ${iraf}lib/libsys.a ${iraf}lib/libvops.a ${hlib}libos.a"
else
	setenv	HSI_CF "$HSI_CF -DNOVOS"
	setenv	HSI_LIBS "${hlib}libboot.a ${hlib}libos.a"
endif

alias	mkiraf	${hlib}mkiraf.csh
alias	mkmlist	${hlib}mkmlist.csh
alias	mkv	${hbin}mkpkg.e lflags="-/Bstatic"	# include tv syms
alias	mkz	${hbin}mkpkg.e lflags=-z		# no shared lib

alias	edsym	${hbin}edsym.e
alias	generic	${hbin}generic.e
alias	mkpkg	${hbin}mkpkg.e
alias	rmbin	${hbin}rmbin.e
alias	rmfiles	${hbin}rmfiles.e
alias	rtar	${hbin}rtar.e
alias	wtar	${hbin}wtar.e
alias	xc	${hbin}xc.e
alias	xyacc	${hbin}xyacc.e
