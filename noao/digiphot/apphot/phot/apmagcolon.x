include "../lib/display.h"
include "../lib/phot.h"

# APMAGCOLON -- Procedure to display and edit the photometry parameters.

procedure apmagcolon (ap, out, stid, cmdstr, newmagbuf, newmag)

pointer	ap		# pointer to apphot structure
int	out		# output file descriptor
int	stid		# output number
char	cmdstr[ARB]	# command string
int	newmagbuf	# new aperture buffers
int	newmag		# compute new magnitudes

bool	bval
int	ncmd
pointer	sp, cmd
real	rval
bool	itob()
int	btoi(), strdic(), nscan(), apstati()
real	apstatr()

begin
	# Get the command.
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)

	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS)
	    return

	# Process the command
	ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, PCMDS)
	switch (ncmd) {
	case PCMD_APERTURES:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        call apstats (ap, APERTS, Memc[cmd], SZ_LINE)
	        call printf ("%s = %s %s\n")
		    call pargstr (KY_APERTS)
		    call pargstr (Memc[cmd])
		    call pargstr (UN_APERTS)
	    } else {
		call apsets (ap, APERTS, Memc[cmd])
		if (stid > 1)
		    call ap_sparam (out, KY_APERTS, Memc[cmd], UN_APERTS,
			"list of aperture radii")
		newmag = YES
		newmagbuf = YES
	    }
	case PCMD_ZMAG:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (KY_ZMAG)
		    call pargr (apstatr (ap, ZMAG))
	    } else {
		call apsetr (ap, ZMAG, rval)
		if (stid > 1)
		    call ap_rparam (out, KY_ZMAG, rval, UN_ZMAG,
			"zero point of magnitude scale")
		newmag = YES
	    }
	case PCMD_MKAPERT:
	    call gargb (bval)
	    if (nscan () == 1) {
		call printf ("%s = %b\n")
		    call pargstr (KY_MKAPERT)
		    call pargb (itob (apstati (ap, MKAPERT)))
	    } else {
		call apseti (ap, MKAPERT, btoi (bval))
	    }
	default:
	    call printf ("Unknown command\7\n")
	}

	call sfree (sp)
end