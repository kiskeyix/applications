/* The Computer Language Shootout
   http://shootout.alioth.debian.org/

   contributed by Greg Buchholz

   for the debian (AMD) machine...
   compile flags:  -O3 -ffast-math -march=athlon-xp -funroll-loops


g++ -march=native -msse2 -mfpmath=387 -O3 -funroll-loops -fomit-frame-pointer -ffast-math -fstrict-aliasing -fwhole-program  mandelbrot_long.cpp -o mandelbrot_long_gcc

g++ -march=native -msse2 -mfpmath=sse -O3 -funroll-loops -fomit-frame-pointer -ffast-math -fstrict-aliasing -fwhole-program  mandelbrot_long.cpp -o mandelbrot_long_gcc

icc -xT -fast mandelbrot_long.cpp -o mandelbrot_long_icc

*/

#include<stdio.h>
#include<stdlib.h>
#include <sys/time.h>
#include <time.h>

#define ITER 50
#define LIMIT_SQUARE 4.0

int main (int argc, char **argv)
{
   static struct timeval _tstart, _tend;

 static struct timezone tz;

  for (int j=1;j<argc;j++)
  {
	 int size = atoi(argv[j]);
	  gettimeofday(&_tstart, &tz);

	   int count = 0;
	   double x, y;;
	   double Zr, Zi, Cr, Ci, Tr, Ti;
	  double fac = 2.0 / size;


	    for(y=0;y<size;++y)
	    {
	        for(x=0;x<size;++x)
	        {
	            Zr = Zi = Tr = Ti = 0.0;
	            Cr = (x*fac - 1.5); Ci=(y*fac - 1.0);

                           int i = ITER;
                           double ZrN = 0;
                           double ZiN = 0;
                           do {
                                   Zi = 2.0 * Zr * Zi + Ci;
                                   Zr = ZrN - ZiN + Cr;
                                   ZiN = Zi * Zi;
                                   ZrN = Zr * Zr;
                           } while (!(ZiN + ZrN > LIMIT_SQUARE) && --i > 0);

	            if(i==0) ++count;
	        }
	    }
		gettimeofday(&_tend,&tz);
	        double t1 =  (double)_tstart.tv_sec*1000.0 + (double)_tstart.tv_usec/(1000.0);
	        double t2 =  (double)_tend.tv_sec*1000.0 + (double)_tend.tv_usec/(1000.0);
		fprintf(stderr,"duration %f  count=%d\n",(t2-t1),count);
	}
}

