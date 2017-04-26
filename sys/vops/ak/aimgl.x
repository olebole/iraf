# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

# AIMG -- Return the imaginary part of a COMPLEX vector.

procedure aimgl (a, b, npix)

complex	a[ARB]
long	b[ARB]
int	npix, i

begin
	do i = 1, npix
	    b[i] = aimag (a[i])
end
