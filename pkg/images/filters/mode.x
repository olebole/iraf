# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include <imset.h>
include <imhdr.h>

# MOD_BOX -- Modal filter an image using a rectangular window

procedure mod_box (im1, im2, boundary, constant)

pointer	im1		# pointer to the input image
pointer	im2		# pointer to the output image
int	boundary	# boundary extension type
real	constant	# constant for constant boundary extension

int	col1, col2, ncols, line, line1, line2
pointer	inbuf, outbuf

pointer	impl2r()

errchk	impl2r, med_buf, mod_boxset, mod_boxfilter

include "mode.com"

begin
	# Check for 1D images
	if (IM_NDIM(im1) == 1)
	    ybox = 1

	# Set the input image boundary extension parameters
	call imseti (im1, IM_TYBNDRY, boundary)
	call imseti (im1, IM_NBNDRYPIX, max (xbox / 2, ybox / 2))
	call imsetr (im1, IM_BNDRYPIXVAL, constant)

	# Set line buffer parameters
	inbuf = NULL
	col1 = 1 - xbox / 2
	col2 = IM_LEN(im1, 1) + xbox / 2 
	ncols = col2 - col1 + 1

	# Generate the output image line by line
	do line = 1, IM_LEN(im2, 2) {

	    # Get ybox image lines
	    line1 = line - ybox / 2
	    line2 = line + ybox / 2

	    # Read in the appropriate range of image lines
	    call med_buf (im1, col1, col2, line1, line2, inbuf)

	    # Set up median filter array for each image line
	    call mod_boxset (Memr[inbuf], ncols, ybox, line)

	    # Get output image line
	    outbuf = impl2r (im2, line)
	    if (outbuf == EOF)
		call error (0, "Error writing output image.")

	    # Median filter the image line
	    if (ybox == 1)
		call mod_xfilter (Memr[inbuf], ncols, ybox, Memr[outbuf],
		    int (IM_LEN(im2,1)))
	    else if (xbox == 1)
		call mod_yfilter (Memr[inbuf], ncols, ybox, Memr[outbuf],
		    int (IM_LEN(im2,1)))
	    else
	        call mod_boxfilter (Memr[inbuf], ncols, ybox, Memr[outbuf],
		    int (IM_LEN(im2, 1)), line)
	}

	# Free image buffer
	call mfree (inbuf, TY_REAL)
end

# MOD_BOXSET -- Set up median array for the beginning of each image line
# The image is raster scanned so that the direction of scanning changes
# for each line. Odd numbered lines are scanned forwards and even numbered
# lines are scanned backward. If the modal filter is one dimensional
# the lines are scanned forward.

procedure mod_boxset (data, nx, ny, line)

real	data[nx, ny]			# image data buffer
int	nx				# number of columns in image buffer
int	ny				# number of lines in the image buffer
int	line				# line number

int	i, j, k, l
pointer	sp, insert, index

include "mode.com"

begin
	call smark (sp)

	# Initialize
	if (xbox == 1) {

	    sum = 0
	    do i = 1, ybox {
		sum = sum + data[1,i]
		filter[i] = data[1,i]
	    }

	    call med_ashsrt (filter, ybox)

	} else if (line == 1 || ybox == 1) {
	    
	    mp = 1

	    call salloc (index, npts, TY_INT)

	    # Load the filter kernel.
	    k = 1
	    sum = 0
	    do i = 1, xbox {
		do j = 1, ybox {
		    sum = sum + data[i,j]
		    filter[k] = data[i,j]
		    Memi[index+k-1] = k
		    k = k + 1
		}
	    }

	    # Sort the initial filter kernel index array
	    call med_gshsrt (filter, Memi[index], npts)

	    # Set up the sorted linked list parameters.
	    start = Memi[index]
	    finish = Memi[index+npts-1]

	    left[start] = 0
	    do i = 2, npts
		left[Memi[index+i-1]] = Memi[index+i-2]

	    do i = 1, npts - 1
		right[Memi[index+i-1]] = Memi[index+i]
	    right[finish] = npts + 1

	} else {
	    
	    call salloc (index, xbox, TY_INT)
	    call salloc (insert, xbox, TY_REAL)

	    # Xbox elements are deleted when lines are changed.
	    # These elements are always located in the first
	    # column of the filter kernel.

	    do i = 1, npts, ybox {

		sum = sum - filter[i]

		if (i == start) {
		    start = right[i]
		    left[right[i]] = 0
		} else if (i == finish) {
		    finish = left[i]
		    right[left[i]] = nptsp1
		} else {
		    left[right[i]] = left[i]
		    right[left[i]] = right[i]
		}
	    }

	    # Find points to be inserted
	    if (mod (line, 2) == 0) {
		j = nx - xbox + 1 
	        do i = 1, xbox {
		    sum = sum + data[j,ny]
		    Memr[insert+i-1] = data[j,ny]
		    Memi[index+i-1] = i
		    j = j + 1
	        }
	    } else {
	        j = 1
	        do i = 1, xbox {
		    sum = sum + data[j,ny]
		    Memr[insert+i-1] = data[j,ny]
		    Memi[index+i-1] = i
		    j = j + 1
	        }
	    }

	    # Sort the new points.
	    call med_gshsrt (Memr[insert], Memi[index], xbox)

	    # Adjust the median pointer
	    mp = mod (mp + ybox, npts)

	    # Do a merge sort of the old and new points
	    j = start
	    do i = 1, xbox {

		# Insert the new point into the filter kernel
		l = Memi[index+i-1]
		k = mod (mp + (l - 1) * ybox, npts)
		filter[k] = Memr[insert+l-1]

		# Find the element to the right of the inserted point
		while (j != right[finish] && Memr[insert+l-1] > filter[j])
		    j = right[j]

		# Make insertions by adjusting the forward and backward links
		if (j == start) {
		    left[start] = k
		    left[k] = 0
		    right[k] = start
		    start = k
		} else if (j == right[finish]) {
		    right[finish] = k
		    left[k] = finish
		    right[k] = npts + 1
		    finish = k
		} else {
		    left[k] = left[j]
		    right[k] = right[left[j]]
		    right[left[j]] = k
		    left[j] = k
		}
	    }

	    # Adjust the filter kernel pointer for backscanned lines
	    if (mod (line, 2) == 0) {
		mp = mod (mp - 2 * ybox, npts)
		if (mp < 1)
		    mp = npts + mp
	    }

	}

	call sfree (sp)
end

# MOD_BOX_FILTER -- Modal filter a single image line

procedure mod_boxfilter (data, nx, ny, mode, ncols, line)

real	data[nx, ny]	# Image data
int	nx, ny		# Dimensions of data
real	mode[ncols]	# Median array
int	ncols		# Number of output image columns
int	line		# current line number

begin
	if (mod (line, 2) == 0)
	    call mod_rev_boxfilter (data, nx, ny, mode, ncols)
	else
	    call mod_forward_boxfilter (data, nx, ny, mode, ncols)
end

# MOD_FORWARD_BOXFILTER -- Modal filter a single image line

procedure mod_forward_boxfilter (data, nx, ny, mode, ncols)

real	data[nx, ny]	# Image data
int	nx, ny		# Dimensions of data
real	mode[ncols]	# Median array
int	ncols		# Number of output image columns

int	i, j, k, l, col
pointer	sp, index

include	"mode.com"

begin
	call smark (sp)
	call salloc (index, ybox, TY_INT)

	col = 1 + xbox
	do i = 1, ncols - 1 {

	    # Calculate the median
	    k = start
	    do j = 1, nhalf
	        k = right[k]
	    mode[i] = 3. * filter[k] - 2. * sum / npts

	    # Delete points
	    do j = mp, mp + ybox - 1 {

		sum = sum - filter[j]

		if (j == start) {
		    start = right[j]
		    left[right[j]] = 0
		} else if (j == finish) {
		    finish = left[j]
		    right[left[j]] = nptsp1
		} else {
		    right[left[j]] = right[j]
		    left[right[j]] = left[j]
		}

	    }

	    # Update median kernel
	    do j = 1, ybox {
		sum = sum + data[col,j]
		filter[mp+j-1] = data[col,j]
		Memi[index+j-1] = j
	    }

	    # Sort array to be inserted
	    call med_gshsrt (filter[mp], Memi[index], ybox)

	    # Merge the sorted lists
	    k = start
	    do j = 1, ybox {

		# Position in filter kernel of new point
		l = Memi[index+j-1] + mp - 1

		# Find the element to the right of the point to be inserted
		while (filter[l] > filter[k] && k != right[finish])
		    k = right[k]

		# Update the linked list
		if (k == start) {
		    left[start] = l
		    left[l] = 0
		    right[l] = start
		    start = l
		} else if (k == right[finish]) {
		    right[finish] = l
		    left[l] = finish
		    right[l] = nptsp1
		    finish = l
		} else {
		    left[l] = left[k]
		    right[l] = right[left[k]]
		    right[left[k]] = l
		    left[k] = l
		}

	    }

	    # Increment the median pointer
	    mp = mp + ybox
	    if (mp > npts)
		mp = 1

	    col = col + 1
	}

	# Calculate the last median
	k = start
	do j = 1, nhalf
	    k = right[k]
	mode[ncols] = 3. * filter[k] - 2. * sum / npts

	call sfree (sp)
end

# MOD_REV_BOXFILTER -- Modal filter a single image line in reverse

procedure mod_rev_boxfilter (data, nx, ny, mode, ncols)

real	data[nx, ny]	# Image data
int	nx, ny		# Dimensions of data
real	mode[ncols]	# Median array
int	ncols		# Number of output image columns

int	i, j, k, l, col
pointer	sp, index

include	"mode.com"

begin
	call smark (sp)
	call salloc (index, ybox, TY_INT)

	col = nx - xbox
	do i = ncols, 2, - 1 {

	    # Calculate the mode
	    k = start
	    do j = 1, nhalf
	        k = right[k]
	    mode[i] = 3. * filter[k] - 2. * sum / npts

	    # Delete points
	    do j = mp, mp + ybox - 1 {

		sum = sum - filter[j]

		if (j == start) {
		    start = right[j]
		    left[right[j]] = 0
		} else if (j == finish) {
		    finish = left[j]
		    right[left[j]] = nptsp1
		} else {
		    right[left[j]] = right[j]
		    left[right[j]] = left[j]
		}

	    }

	    # Update median kernel
	    do j = 1, ybox {
		sum = sum + data[col,j]
		filter[mp+j-1] = data[col,j]
		Memi[index+j-1] = j
	    }

	    # Sort array to be inserted
	    call med_gshsrt (filter[mp], Memi[index], ybox)

	    # Merge the sorted lists
	    k = start
	    do j = 1, ybox {

		# Position in filter kernel of new point
		l = Memi[index+j-1] + mp - 1

		# Find the element to the right of the point to be inserted
		while (filter[l] > filter[k] && k != right[finish])
		    k = right[k]

		# Update the linked list
		if (k == start) {
		    left[start] = l
		    left[l] = 0
		    right[l] = start
		    start = l
		} else if (k == right[finish]) {
		    right[finish] = l
		    left[l] = finish
		    right[l] = nptsp1
		    finish = l
		} else {
		    left[l] = left[k]
		    right[l] = right[left[k]]
		    right[left[k]] = l
		    left[k] = l
		}

	    }

	    # Increment the median pointer
	    mp = mp - ybox
	    if (mp < 1)
		mp = mp + npts

	    col = col - 1
	}

	# Calculate the last mode
	k = start
	do j = 1, nhalf
	    k = right[k]
	mode[1] = 3. * filter[k] - 2. * sum / npts

	call sfree (sp)
end

# MOD_XFILTER -- Modal filter a single image line in the x direction.
# The filter always moves from left to right.

procedure mod_xfilter (data, nx, ny, mode, ncols)

real	data[nx, ny]	# Image data
int	nx, ny		# Dimensions of data
real	mode[ncols]	# Mode array
int	ncols		# Number of output image columns

int	i, j, k

include	"mode.com"

begin
	# Modal filter an image line
	do i = 1, ncols - 1 {

	    # Calculate the mode
	    k = start
	    do j = 1, nhalf
	        k = right[k]
	    mode[i] = 3. * filter[k] - 2. * sum / npts

	    # Delete points from the filter kernel

	    sum = sum - filter[mp]

	    if (mp == start) {
		start = right[mp]
		left[right[mp]] = 0
	    } else
		right[left[mp]] = right[mp]

	    if (mp == finish) {
		finish = left[mp]
		right[left[mp]] = nptsp1
	    } else
		left[right[mp]] = left[mp]

	    # Update median kernel
	    sum = sum + data[i+xbox,1]
	    filter[mp] = data[i+xbox,1]

	    # Find the point to the right of the point to be inserted
	    k = start
    	    while (k != right[finish] && filter[mp] > filter[k])
		k = right[k]

	    # Insert points into the filter kernel
	    if (k == start) {
		left[start] = mp
		left[mp] = 0
		right[mp] = start
		start = mp
	    } else if (k == right[finish]) {
		right[finish] = mp
		left[mp] = finish
		right[mp] = nptsp1
		finish = mp
	    } else {
		left[mp] = left[k]
		right[mp] = right[left[k]]
		right[left[k]] = mp
		left[k] = mp
	    }

	    # Increment median counter
	    mp = mp + 1
	    if (mp > npts)
		mp = 1
	}

	# Calculate the last mode
	k = start
	do j = 1, nhalf
	    k = right[k]
	mode[ncols] = 3. * filter[k] - 2. * sum / npts
end

# MOD_YFILTER -- Modal filter a single image line in the y direction

procedure mod_yfilter (data, nx, ny, mode, ncols)

real	data[nx, ny]	# Image data
int	nx, ny		# Dimensions of data
real	mode[ncols]	# Modal array
int	ncols		# Number of output image columns

int	i, j

include	"mode.com"

begin
	do i = 1, ncols - 1 {

	    # Calculate the new median
	    mode[i] = 3. * filter[nhalf+1] - 2. * sum / npts

	    # Update median kernel
	    sum = 0.
	    do j = 1, ybox {
		sum = sum + data[i+1,j]
	        filter[j] = data[i+1,j]
	    }

	    call med_ashsrt (filter, ybox)

	}

	# Calculate the last mode
	mode[ncols] = 3. * filter[nhalf+1] - 2. * sum / npts
end