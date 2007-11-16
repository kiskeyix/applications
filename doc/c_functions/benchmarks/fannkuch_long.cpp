/*
 * The Computer Lannguage Shootout
 * http://shootout.alioth.debian.org/
 * Contributed by Heiner Marxen
 *
 * "fannkuch"	for C gcc
 *
 * $Id: fannkuch-gcc.code,v 1.44 2007-05-19 00:42:42 igouy-guest Exp $

g++ -march=native -msse2 -mfpmath=387 -O3 -funroll-loops -fomit-frame-pointer -ffast-math -fstrict-aliasing -fwhole-program  fannkuch_long.cpp -o fannkuch_long_gcc

g++ -march=native -msse2 -mfpmath=sse -O3 -funroll-loops -fomit-frame-pointer -ffast-math -fstrict-aliasing -fwhole-program  fannkuch_long.cpp -o fannkuch_long_gcc

icc -xT -fast fannkuch_long.cpp -o fannkuch_long_icc


 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>

#define Int	int
#define Aint	int

    static long
fannkuch( int n )
{
    Aint*	perm;
    Aint*	perm1;
    Aint*	count;
    long	flips;
    long	flipsMax;
    Int		r;
    Int		i;
    Int		k;
    Int		didpr;
    const Int	n1	= n - 1;

    if( n < 1 ) return 0;

    perm  = (Aint*)calloc(n, sizeof(*perm ));
    perm1 = (Aint*)calloc(n, sizeof(*perm1));
    count = (Aint*)calloc(n, sizeof(*count));

    for( i=0 ; i<n ; ++i ) perm1[i] = i;	/* initial (trivial) permu */

    r = n; didpr = 0; flipsMax = 0;
    for(;;) {
	for( ; r!=1 ; --r ) {
	    count[r-1] = r;
	}

#define XCH(x,y)	{ Aint t_mp; t_mp=(x); (x)=(y); (y)=t_mp; }

	if( ! (perm1[0]==0 || perm1[n1]==n1) ) {
	    flips = 0;
	    for( i=1 ; i<n ; ++i ) {	/* perm = perm1 */
		perm[i] = perm1[i];
	    }
	    k = perm1[0];		/* cache perm[0] in k */
	    do {			/* k!=0 ==> k>0 */
		Int	j;
		for( i=1, j=k-1 ; i<j ; ++i, --j ) {
		    XCH(perm[i], perm[j])
		}
		++flips;
		/*
		 * Now exchange k (caching perm[0]) and perm[k]... with care!
		 * XCH(k, perm[k]) does NOT work!
		 */
		j=perm[k]; perm[k]=k ; k=j;
	    }while( k );
	    if( flipsMax < flips ) {
		flipsMax = flips;
	    }
	}

	for(;;) {
	    if( r == n ) {
		return flipsMax;
	    }
	    /* rotate down perm[0..r] by one */
	    {
		Int	perm0 = perm1[0];
		i = 0;
		while( i < r ) {
		    k = i+1;
		    perm1[i] = perm1[k];
		    i = k;
		}
		perm1[r] = perm0;
	    }
	    if( (count[r] -= 1) > 0 ) {
		break;
	    }
	    ++r;
	}
    }
}

    int
main( int argc, char* argv[] )
{
   static struct timeval _tstart, _tend;

 static struct timezone tz;

  for (int i=1;i<argc;i++)
  {
	gettimeofday(&_tstart, &tz);

	  int n = atoi(argv[i]);
	printf("Pfannkuchen(%d) = %ld\n", n, fannkuch(n));
	gettimeofday(&_tend,&tz);
        double t1 =  (double)_tstart.tv_sec*1000.0 + (double)_tstart.tv_usec/(1000.0);
        double t2 =  (double)_tend.tv_sec*1000.0 + (double)_tend.tv_usec/(1000.0);
	printf("duration %f\n",(t2-t1));
  }
    return 0;
}

