#define import_spp
#define import_knames
#include <iraf.h>

/* AMOVC -- Copy a block of memory.
 * [Specially optimized for Sun/IRAF].
 */
AMOVC (a, b, n)
XCHAR	*a, *b;
XINT	*n;
{
	bcopy ((char *)a, (char *)b, *n * sizeof(*a));
}