// -*- mode: c++ -*-
//
// The Great Computer Language Shootout
// http://shootout.alioth.debian.org/
//
// Original C contributed by Sebastien Loisel
// Conversion to C++ by Jon Harrop
// Compile: g++ -O3 -o spectralnorm spectralnorm.cpp

/*
g++ -march=native -msse2 -mfpmath=387 -O3 -funroll-loops -fomit-frame-pointer spectralnorm.cpp -o spectralnorm_gcc
g++ -march=native -msse2 -mfpmath=sse -O3 -funroll-loops -ftree-vectorizer -fomit-frame-pointer -ffast-math -fargument-noalias-global -fwhole-program  spectralnorm.cpp -o spectralnorm_gcc
 icc -xT -fast spectralnorm.cpp -o spectralnorm_icc
*/
#include <stdlib.h>
#include <cmath>
#include <vector>
#include <iostream>
#include <iomanip>
#include <sys/time.h>
#include <time.h>


using namespace std;

double eval_A(int i, int j) { return 1.0 / ((i+j)*(i+j+1)/2 + i + 1); }

void eval_A_times_u(const vector<double> &u, vector<double> &Au)
{
  for(int i=0; i<u.size(); i++)
    for(int j=0; j<u.size(); j++) Au[i] += eval_A(i,j) * u[j];
}

void eval_At_times_u(const vector<double> &u, vector<double> &Au)
{
  for(int i=0; i<u.size(); i++)
    for(int j=0; j<u.size(); j++) Au[i] += eval_A(j,i) * u[j];
}

void eval_AtA_times_u(const vector<double> &u, vector<double> &AtAu)
{ vector<double> v(u.size()); eval_A_times_u(u, v); eval_At_times_u(v, AtAu); }

int main(int argc, char *argv[])
{
 static struct timeval _tstart, _tend;

 static struct timezone tz;

  for (int i=1;i<argc;i++)
  {
	gettimeofday(&_tstart, &tz);

	  int N = atoi(argv[i]);
	  vector<double> u(N), v(N);

	  fill(u.begin(), u.end(), 1);

	  for(int i=0; i<10; i++) {
	    eval_AtA_times_u(u, v);
	    fill(u.begin(), u.end(), 0);
	    eval_AtA_times_u(v, u);
	  }

	  double vBv=0, vv=0;
	  for(int i=0; i<N; i++) { vBv += u[i]*v[i]; vv += v[i]*v[i]; }

	  cout << setprecision(10) << sqrt(vBv/vv) << endl;
	gettimeofday(&_tend,&tz);
        double t1 =  (double)_tstart.tv_sec*1000.0 + (double)_tstart.tv_usec/(1000.0);
        double t2 =  (double)_tend.tv_sec*1000.0 + (double)_tend.tv_usec/(1000.0);
	cout << "duration " << (t2-t1) << "\n";
  }
  return 0;
}

