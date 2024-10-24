#ifndef __MEMTRANSFER_H__
#define __MEMTRANSFER_H__

#include <cufinufft_eitherprec.h>
namespace cufinufft {
namespace memtransfer {
int ALLOCGPUMEM1D_PLAN(CUFINUFFT_PLAN d_plan);
int ALLOCGPUMEM1D_NUPTS(CUFINUFFT_PLAN d_plan);
void FREEGPUMEMORY1D(CUFINUFFT_PLAN d_plan);

int ALLOCGPUMEM2D_PLAN(CUFINUFFT_PLAN d_plan);
int ALLOCGPUMEM2D_NUPTS(CUFINUFFT_PLAN d_plan);
void FREEGPUMEMORY2D(CUFINUFFT_PLAN d_plan);

int ALLOCGPUMEM3D_PLAN(CUFINUFFT_PLAN d_plan);
int ALLOCGPUMEM3D_NUPTS(CUFINUFFT_PLAN d_plan);
void FREEGPUMEMORY3D(CUFINUFFT_PLAN d_plan);
} // namespace mem
} // namespace cufinufft
#endif
