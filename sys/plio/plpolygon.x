# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include <plset.h>
include <plio.h>

define	TOL		0.0001		# pixel units
define	swapi		{tempi=$2;$2=$1;$1=tempi}
define	swapr		{tempr=$2;$2=$1;$1=tempr}
define	equal		(abs($1-$2)<TOL)

define	LEN_PGONDES	7
define	P_PL		Memi[$1]	# pointer to X vector
define	P_XP		Memi[$1+1]	# pointer to X vector
define	P_YP		Memi[$1+2]	# pointer to Y vector
define	P_OO		Memi[$1+3]	# pointer to previous range list
define	P_OY		Memi[$1+4]	# y value of previous range list
define	P_NS		Memi[$1+5]	# number of line segments
define	P_PV		Memi[$1+6]	# pixel value


# PL_POLYGON -- Perform a rasterop operation on the area enclosed by a polygon
# drawn in a 2-dimensional plane of a mask.  If the dimensionality of the mask
# exceeds 2, the pl_setplane() procedure should be called first to define the
# plane of the mask to be modified.

procedure pl_polygon (pl, x, y, npts, rop)

pointer	pl			#I mask descriptor
int	x[npts]			#I polygon x-vertices
int	y[npts]			#I polygon y-vertices
int	npts			#I number of points in polygon
int	rop			#I rasterop defining operation

int	line_1, line_2, i
pointer	sp, ufd, xp, yp, oo
bool	pl_upolygon()
extern	pl_upolygon()
errchk	plvalid

begin
	call plvalid (pl)
	if (npts <= 0)
	    return
	else if (npts == 1) {
	    call pl_point (pl, x[1], y[1], rop)
	    return
	}

	call smark (sp)
	call salloc (ufd, LEN_PGONDES, TY_STRUCT)
	call salloc (oo, RL_FIRST + (npts+1)*3, TY_INT)
	call salloc (xp, npts + 1, TY_REAL)
	call salloc (yp, npts + 1, TY_REAL)

	# Initialize the region descriptor.
	P_PL(ufd) = pl
	P_XP(ufd) = xp
	P_YP(ufd) = yp
	P_PV(ufd) = 1
	P_OO(ufd) = oo
	P_OY(ufd) = -1
	P_NS(ufd) = npts - 1
	RLI_LEN(oo) = 0

	# Copy the user supplied polygon vertices into the descriptor,
	# normalizing the polygon in the process.

	do i = 1, npts {
	    Memr[xp+i-1] = x[i]
	    Memr[yp+i-1] = y[i]
	}

	if (npts > 2)
	    if (abs(x[1]-x[npts]) > TOL || abs(y[1]-y[npts]) > TOL) {
		Memr[xp+npts] = x[1]
		Memr[yp+npts] = y[1]
		P_NS(ufd) = npts
	    }

	# Compute the range in Y in which the polygon should be drawn.
	call alimi (y, npts, line_1, line_2)

	call pl_regionrop (pl, pl_upolygon, ufd, line_1, line_2, rop)
	call sfree (sp)
end


# PL_UPOLYGON -- Regionrop ufcn for a general closed polygonal region.
# (surely there must be a simpler way to code this...)

bool procedure pl_upolygon (ufd, line, rl_reg, xs, npix)

pointer	ufd			#I user function descriptor
int	line			#I mask line number
int	rl_reg[3,ARB]		#O output range list for line Y
int	xs			#O start of edit region in dst mask
int	npix			#O number of pixels affected

pointer	xp, yp, pl
bool	rl_new, cross
int	nseg, np, low, rn, i1, i2, ii, i, j
int	tempi, axlen, rl_len, p_prev, p_next
real	tempr, y, y1, y2, x1, x2, p1, p2, p_y, n_y

int	btoi()
bool	plr_equali()
define	done_ 91

begin
	pl = P_PL(ufd)
	axlen = PL_AXLEN(pl,1)
	rn = RL_FIRST
	npix = 0
	xs = 1

	nseg = P_NS(ufd)
	xp = P_XP(ufd)
	yp = P_YP(ufd)
	y  = real(line)

	# Find the point(s) of intersection of the current mask line with
	# the line segments forming the polygon.  Note that the line must
	# cross a segment to go from inside to outside or vice versa; if a
	# segment (or vertex) is merely touched it should be drawn, but it
	# is not a point of crossing.

	do i = 1, nseg {
	    # Locate next and previous line segments.
	    if (i == 1)
		p_prev = nseg
	    else
		p_prev = i - 1
	    if (i == nseg)
		p_next = 1
	    else
		p_next = i + 2

	    # Get endpoints of current segment.
	    x1 = Memr[xp+i-1];  x2 = Memr[xp+i]
	    y1 = Memr[yp+i-1];  y2 = Memr[yp+i]
	    if (y1 > y2) {
		swapr (x1, x2)
		swapr (y1, y2)
		swapi (p_next, p_prev)
	    }

	    # Does current line intersect the polygon line segment?
	    if (y > y1-TOL && y < y2+TOL) {
		p_y = Memr[yp+p_prev-1]
		n_y = Memr[yp+p_next-1]

		if (y2 - y1 > TOL) {
		    # Single point of intersection.
		    p1 = x1 + ((x2 - x1) / (y2 - y1)) * (y - y1)
		    p2 = p1

		    if (equal (p1, x1) && equal (y, y1))
			cross = ((p_y - y1) < 0)
		    else if (equal (p1, x2) && equal (y, y2))
			cross = ((n_y - y2) > 0)
		    else
			cross = true

		} else {
		    # Intersection is entire line segment.
		    p1 = x1;  p2 = x2
		    cross = (((p_y - y) * (n_y - y)) < 0)
		}

		i1 = max(1, min(axlen, nint(p1)))
		i2 = max(1, min(axlen, nint(p2)))
		if (i1 > i2)
		    swapi (i1, i2)

		np = i2 - i1 + 1
		if (np > 0) {
		    RL_X(rl_reg,rn) = i1
		    RL_N(rl_reg,rn) = np
		    RL_V(rl_reg,rn) = btoi(cross)
		    rn = rn + 1
		}
	    }
	}

	rl_len = rn - 1
	if (rl_len <= RL_FIRST)
	    goto done_

	# Sort the line intersection-segments in order of increasing X.
	do j = RL_FIRST, rl_len {
	    # Get low X value of initial segment.
	    i1 = RL_X(rl_reg,j)
	    np = RL_N(rl_reg,j)
	    i1 = min (i1, i1 + np - 1)
	    low = j

	    # Find lowest valued segment in remainder of array.
	    do i = j+1, rl_len {
		i2 = RL_X(rl_reg,i)
		np = RL_N(rl_reg,i)
		i2 = min (i2, i2 + np - 1)
		if (i2 < i1) {
		    i1 = i2
		    low = i
		}
	    }
	    
	    # Interchange the initial segment and the low segment.
	    if (low != j) {
		swapi (RL_X(rl_reg,j), RL_X(rl_reg,low))
		swapi (RL_N(rl_reg,j), RL_N(rl_reg,low))
		swapi (RL_V(rl_reg,j), RL_V(rl_reg,low))
	    }
	}

	# Combine any segments which overlap.
	rn = RL_FIRST
	do i = RL_FIRST + 1, rl_len {
	    i1 = RL_X(rl_reg,rn)
	    i2 = RL_N(rl_reg,rn) + i1 - 1
	    ii = RL_X(rl_reg,i)
	    if (ii >= i1 && ii <= i2) {
		i2 = ii + RL_N(rl_reg,i) - 1
		RL_N(rl_reg,rn) = max (RL_N(rl_reg,rn), i2 - i1 + 1)
		RL_V(rl_reg,rn) = max (RL_V(rl_reg,rn), RL_V(rl_reg,i))
	    } else {
		rn = rn + 1
		RL_X(rl_reg,rn) = RL_X(rl_reg,i)
		RL_N(rl_reg,rn) = RL_N(rl_reg,i)
		RL_V(rl_reg,rn) = RL_V(rl_reg,i)
	    }
	}
	rl_len = rn

	# Now combine successive pairs of intersections to produce the line
	# segments to be drawn.  If all points are crossing points (where the
	# image line crosses the polygon boundary) then we draw a line between
	# the first two points, then the second two points, and so on.  Points
	# where the image line touches the polygon boundary but does not cross
	# it are plotted, but are not joined with other points to make line
	# segments.

	rn = RL_FIRST
	ii = RL_FIRST

	do j = RL_FIRST, rl_len {
	    if (j <= ii && j < rl_len) {
		next

	    } else if (RL_V(rl_reg,ii) == YES) {
		# Skip a vertext that touches but does not cross.
		if (RL_V(rl_reg,j) == NO && j < rl_len)
		    next

		# Draw a line between the two crossing points.
		RL_X(rl_reg,rn) = RL_X(rl_reg,ii)
		RL_N(rl_reg,rn) = max (RL_N(rl_reg,ii),
		    RL_X(rl_reg,j) + RL_N(rl_reg,j) - RL_X(rl_reg,ii))
		RL_V(rl_reg,rn) = P_PV(ufd)
		rn = rn + 1
		ii = j + 1

	    } else {
		# Plot only the first point.
		RL_X(rl_reg,rn) = RL_X(rl_reg,ii)
		RL_N(rl_reg,rn) = RL_N(rl_reg,ii)
		RL_V(rl_reg,rn) = P_PV(ufd)
		rn = rn + 1

		if (j >= rl_len && j != ii) {
		    # Plot the second point, if and end of list.
		    RL_X(rl_reg,rn) = RL_X(rl_reg,j)
		    RL_N(rl_reg,rn) = RL_N(rl_reg,j)
		    RL_V(rl_reg,rn) = P_PV(ufd)
		    rn = rn + 1
		} else
		    ii = j
	    }
	}

done_
	# Convert the X values in the range list to be relative to the start
	# of the list.  Compute NPIX, the range in pixels spanned by the range
	# list.

	rl_len = rn - 1
	xs = RL_X(rl_reg,RL_FIRST)
	npix = RL_X(rl_reg,rl_len) + RL_N(rl_reg,rl_len) - xs

	do i = RL_FIRST, rl_len
	    RL_X(rl_reg,i) = RL_X(rl_reg,i) - xs + 1

	RL_LEN(rl_reg) = rl_len
	RL_AXLEN(rl_reg) = npix

	rl_new = true
	if (P_OY(ufd) == line - 1)
	    rl_new = !plr_equali (rl_reg, Memi[P_OO(ufd)])
	call amovi (rl_reg, Memi[P_OO(ufd)], rn - 1)
	P_OY(ufd) = line

	return (rl_new)
end
