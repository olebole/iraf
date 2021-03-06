# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<gset.h>
include	"gks.h"

# GQPLCI -- Inquire Polyline color index.

procedure gqplci (errind, coli)

int	coli			# Color index - returned value
int	errind			# Error indicator
real	gstatr()
include	"gks.com"

begin
	if (gk_std == NULL) {
	    # GKS not in proper state; no active workstations
	    errind = 7
	    coli = -1
	    return
	} else
	    errind = 0

	iferr {
	    coli = int (gstatr (gp[gk_std], G_PLWIDTH))
	} then {
	    errind = 1
	    coli = -1
	}
end
