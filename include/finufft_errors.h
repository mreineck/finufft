#ifndef FINUFFT_ERRORS_H
#define FINUFFT_ERRORS_H

// ---------- Global error/warning output codes for the library ---------------
// All documentation is at ../docs/errors.rst (not here):
enum { FINUFFT_WARN_EPS_TOO_SMALL         = 1,
       FINUFFT_ERR_MAXNALLOC              = 2,
       FINUFFT_ERR_SPREAD_BOX_SMALL       = 3,
       FINUFFT_ERR_SPREAD_PTS_OUT_RANGE   = 4, // DEPRECATED
       FINUFFT_ERR_SPREAD_ALLOC           = 5,
       FINUFFT_ERR_SPREAD_DIR             = 6,
       FINUFFT_ERR_UPSAMPFAC_TOO_SMALL    = 7,
       FINUFFT_ERR_HORNER_WRONG_BETA      = 8,
       FINUFFT_ERR_NTRANS_NOTVALID        = 9,
       FINUFFT_ERR_TYPE_NOTVALID          = 10,
       FINUFFT_ERR_ALLOC                  = 11,
       FINUFFT_ERR_DIM_NOTVALID           = 12,
       FINUFFT_ERR_SPREAD_THREAD_NOTVALID = 13,
       FINUFFT_ERR_NDATA_NOTVALID         = 14,
       FINUFFT_ERR_CUDA_FAILURE           = 15,
       FINUFFT_ERR_PLAN_NOTVALID          = 16,
       FINUFFT_ERR_METHOD_NOTVALID        = 17,
       FINUFFT_ERR_BINSIZE_NOTVALID       = 18,
       FINUFFT_ERR_INSUFFICIENT_SHMEM     = 19,
       FINUFFT_ERR_NUM_NU_PTS_INVALID     = 20};
#endif
