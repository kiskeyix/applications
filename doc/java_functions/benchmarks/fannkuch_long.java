/* The Great Computer Language Shootout
   http://shootout.alioth.debian.org/

   contributed by Paul Lofte
*/

public class fannkuch_long {
	    public static void main(String[] args) {
	        for (int i=0;i<args.length;i++)
	        {
	        	int n = Integer.parseInt(args[i]);
	        	long t1 = System.nanoTime();
	        	System.out.println("Pfannkuchen(" + n + ") = " + fannkuch(n));
	        	long t2 = System.nanoTime();
	        	System.out.println("Duration "+(t2-t1)/1000.0/1000.0);
	        }
	    }

	    public static int fannkuch(int n) {
	        int check = 0;
	        int[] perm = new int[n];
	        int[] perm1 = new int[n];
	        int[] count = new int[n];
	        int[] maxPerm = new int[n];
	        int maxFlipsCount = 0;
	        int m = n - 1;

	        for (int i = 0; i < n; i++) perm1[i] = i;
	        int r = n;

	        while (true) {
	            // write-out the first 30 permutations

	            while (r != 1) { count[r - 1] = r; r--; }
	            if (!(perm1[0] == 0 || perm1[m] == m)) {
	                for (int i = 0; i < n; i++) perm[i] = perm1[i];

	                int flipsCount = 0;
	                int k;

	                while (!((k = perm[0]) == 0)) {
	                    int k2 = (k + 1) >> 1;
	                    for (int i = 0; i < k2; i++) {
	                        int temp = perm[i]; perm[i] = perm[k - i]; perm[k - i] = temp;
	                    }
	                    flipsCount++;
	                }

	                if (flipsCount > maxFlipsCount) {
	                    maxFlipsCount = flipsCount;
	                    for (int i = 0; i < n; i++) maxPerm[i] = perm1[i];
	                }
	            }

	            while (true) {
	                if (r == n) return maxFlipsCount;
	                int perm0 = perm1[0];
	                int i = 0;
	                while (i < r) {
	                    int j = i + 1;
	                    perm1[i] = perm1[j];
	                    i = j;
	                }
	                perm1[r] = perm0;

	                count[r] = count[r] - 1;
	                if (count[r] > 0) break;
	                r++;
	            }
	        }
	    }
	}
