# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<imhdr.h>

# IMGS2? -- Get a section from an apparently two dimensional image.

pointer procedure imgs2r (im, x1, x2, y1, y2)

pointer	im
int	x1, x2, y1, y2
long	vs[2], ve[2]
pointer	imggsr(), imgl2r()

begin
	if (x1 == 1 && x2 == IM_LEN(im,1) && y1 == y2)
	    return (imgl2r (im, y1))
	else {
	    vs[1] = x1
	    ve[1] = x2

	    vs[2] = y1
	    ve[2] = y2

	    return (imggsr (im, vs, ve, 2))
	}
end
