import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;

/* The Great Computer Language Shootout
http://shootout.alioth.debian.org/

contributed by Lester Vecsey 
modified by Stefan Krause
*/
class mandelbrot_long {
	
    final static double limitSquared = 4.0;
    final static int iterations = 50;
	
   public static void main(String[] args) throws Exception {
	   for (int i=0;i<args.length;i++)
	   {
		   int size = Integer.parseInt(args[i]);
		   System.out.println("Run # "+i);
		   long t1 = System.nanoTime();
		   Mandelbrot m = new Mandelbrot(size);
		   int r = m.compute();
		   long t2 = System.nanoTime();
		   System.err.println("duration ="+(t2-t1)/1000.0/1000.0+" msec. count="+r);
	   }
   }   

   public static class Mandelbrot {
	   public Mandelbrot(int size)
	   {
		   this.size = size;
		   fac = 2.0 / size;
		   out = new BufferedOutputStream(System.out);
		   
		   int offset = size % 8;
		   shift = offset == 0 ? 0 : (8-offset);
	   }
	   final int size;
	   final BufferedOutputStream out;
	   final double fac;
	   final int shift;

	   public int compute() throws IOException
	   {
		   int t = 0;
		   for (int y = 0; y<size; y++)
			   t+=computeRow(y);
		   out.close();
		   return t;
	   }
		   
	   private int computeRow(int y) throws IOException
	   {		   
		   int count=0;

		   for (int x = 0; x<size;x++) {
			   double Zr = 0.0;
			   double Zi = 0.0;
	           double Cr = (x*fac - 1.5); 
	           double Ci = (y*fac - 1.0);

			   int i = iterations;
			   double ZrN = 0;
			   double ZiN = 0;
			   do {
				   Zi = 2.0 * Zr * Zi + Ci;
				   Zr = ZrN - ZiN + Cr;
				   ZiN = Zi * Zi;
				   ZrN = Zr * Zr;
			   } while (!(ZiN + ZrN > limitSquared) && --i > 0);

	            if (i == 0) count++;
		   }
		   return count;
	   }
   }
 }
