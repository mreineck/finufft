#ifndef FINUFFT_INCLUDE_FINUFFT_FFT_H
#define FINUFFT_INCLUDE_FINUFFT_FFT_H

#include <vector>
#ifndef FINUFFT_USE_DUCC0
#include "fftw_defs.h"
#endif
#include <finufft/defs.h>

#ifdef FINUFFT_USE_DUCC0
static inline void finufft_fft_forget_wisdom() {}
static inline void finufft_fft_cleanup() {}
static inline void finufft_fft_cleanup_threads() {}
#else
static inline void finufft_fft_forget_wisdom() {
  Finufft_FFTW_plan<FLT>::forget_wisdom();
}
static inline void finufft_fft_cleanup() { Finufft_FFTW_plan<FLT>::cleanup(); }
static inline void finufft_fft_cleanup_threads() {
  Finufft_FFTW_plan<FLT>::cleanup_threads();
}
#endif

std::vector<int> gridsize_for_fft(FINUFFT_PLAN p);
void do_fft(FINUFFT_PLAN p);

#endif // FINUFFT_INCLUDE_FINUFFT_FFT_H
