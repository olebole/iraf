# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

# ICG_INSERT -- Insert a point.

procedure icg_insertr (wx, wy, wt, x, y, w1, w2, npts)

real	wx				# X point to insert	
real	wy				# Y point to insert	
real	wt				# Weight of point to insert
real	x[npts]				# Independent variable
real	y[npts]				# Dependent variable
real	w1[npts]			# Current weights
real	w2[npts]			# Initial weights
int	npts				# Number of points

int	i, j

begin
	# Find the place to insert the new point.
	if (x[1] < x[npts])
	    for (i = npts; (i > 0) && (wx < x[i]); i = i - 1)
		;
	else
	    for (i = npts; (i > 0) && (wx > x[i]); i = i - 1)
		;

	# Shift the data to insert the new point.
	for (j = npts; j > i; j = j - 1) {
	    x[j+1] = x[j]
	    y[j+1] = y[j]
	    w1[j+1] = w1[j]
	    w2[j+1] = w2[j]
	}

	# Add the new point and increment the number of points.
	i = i + 1
	x[i] = wx
	y[i] = wy
	w1[i] = wt
	w2[i] = wt
	npts = npts + 1
end