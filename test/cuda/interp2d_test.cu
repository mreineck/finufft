#include <cmath>
#include <complex>
#include <helper_cuda.h>
#include <iomanip>
#include <iostream>
#include <random>

#include <cufinufft/common.h>
#include <cufinufft/spreadinterp.h>
#include <cufinufft/utils.h>

using namespace cufinufft::common;
using namespace cufinufft::spreadinterp;
using namespace cufinufft::utils;

int main(int argc, char *argv[]) {
    int nf1, nf2;
    CUFINUFFT_FLT upsampfac = 2.0;
    int N1, N2, M;
    if (argc < 5) {
        fprintf(stderr, "Usage: interp2d method nupts_distr nf1 nf2 [M [tol [kerevalmeth [sort]]]]\n"
                        "Arguments:\n"
                        "  method: One of\n"
                        "    1: nupts driven, or\n"
                        "    2: sub-problem.\n"
                        "  nupts_distr: The distribution of the points; one of\n"
                        "    0: uniform, or\n"
                        "    1: concentrated in a small region.\n"
                        "  nf1, nf2: The size of the 2D array.\n"
                        "  M: The number of non-uniform points (default nf1 * nf2 / 4).\n"
                        "  tol: NUFFT tolerance (default 1e-6).\n"
                        "  kerevalmeth: Kernel evaluation method; one of\n"
                        "     0: Exponential of square root (default), or\n"
                        "     1: Horner evaluation.\n"
                        "  sort: One of\n"
                        "     0: do not sort the points, or\n"
                        "     1: sort the points (default).\n");
        return 1;
    }
    double w;
    int method;
    sscanf(argv[1], "%d", &method);
    int nupts_distribute;
    sscanf(argv[2], "%d", &nupts_distribute);
    sscanf(argv[3], "%lf", &w);
    nf1 = (int)w; // so can read 1e6 right!
    sscanf(argv[4], "%lf", &w);
    nf2 = (int)w; // so can read 1e6 right!

    N1 = (int)nf1 / upsampfac;
    N2 = (int)nf2 / upsampfac;
    M = N1 * N2; // let density always be 1
    if (argc > 5) {
        sscanf(argv[5], "%lf", &w);
        M = (int)w; // so can read 1e6 right!
        if (M == 0)
            M = N1 * N2;
    }

    CUFINUFFT_FLT tol = 1e-6;
    if (argc > 6) {
        sscanf(argv[6], "%lf", &w);
        tol = (CUFINUFFT_FLT)w; // so can read 1e6 right!
    }

    int kerevalmeth = 0;
    if (argc > 7) {
        sscanf(argv[7], "%d", &kerevalmeth);
    }

    int sort = 1;
    if (argc > 8) {
        sscanf(argv[8], "%d", &sort);
    }

    int ier;
    std::cout << std::scientific << std::setprecision(3);

    CUFINUFFT_FLT *x, *y;
    CUFINUFFT_CPX *c, *fw;
    cudaMallocHost(&x, M * sizeof(CUFINUFFT_FLT));
    cudaMallocHost(&y, M * sizeof(CUFINUFFT_FLT));
    cudaMallocHost(&c, M * sizeof(CUFINUFFT_CPX));
    cudaMallocHost(&fw, nf1 * nf2 * sizeof(CUFINUFFT_CPX));

    CUFINUFFT_FLT *d_x, *d_y;
    CUCPX *d_c, *d_fw;
    checkCudaErrors(cudaMalloc(&d_x, M * sizeof(CUFINUFFT_FLT)));
    checkCudaErrors(cudaMalloc(&d_y, M * sizeof(CUFINUFFT_FLT)));
    checkCudaErrors(cudaMalloc(&d_c, M * sizeof(CUCPX)));
    checkCudaErrors(cudaMalloc(&d_fw, nf1 * nf2 * sizeof(CUCPX)));

    int dim = 2;
    CUFINUFFT_PLAN dplan = new CUFINUFFT_PLAN_S;
    // Zero out your struct, (sets all pointers to NULL, crucial)
    memset(dplan, 0, sizeof(*dplan));
    ier = CUFINUFFT_DEFAULT_OPTS(2, dim, &(dplan->opts));
    dplan->opts.gpu_method = method;
    dplan->opts.gpu_maxsubprobsize = 1024;
    dplan->opts.gpu_kerevalmeth = kerevalmeth;
    dplan->opts.gpu_sort = sort;
    dplan->opts.gpu_spreadinterponly = 1;
    dplan->opts.gpu_binsizex = 32; // binsize needs to be set here, since
                                   // SETUP_BINSIZE() is not called in
                                   // spread, interp only wrappers.
    dplan->opts.gpu_binsizey = 32;
    ier = setup_spreader_for_nufft(dplan->spopts, tol, dplan->opts);

    std::default_random_engine eng(1);
    std::uniform_real_distribution<CUFINUFFT_FLT> dist01(0, 1);
    std::uniform_real_distribution<CUFINUFFT_FLT> dist11(-1, 1);
    auto rand01 = [&eng, &dist01]() { return dist01(eng); };
    auto randm11 = [&eng, &dist11]() { return dist11(eng); };

    switch (nupts_distribute) {
    case 0: // uniform
    {
        for (int i = 0; i < M; i++) {
            x[i] = M_PI * randm11(); // x in [-pi,pi)
            y[i] = M_PI * randm11();
        }
    } break;
    case 1: // concentrate on a small region
    {
        for (int i = 0; i < M; i++) {
            x[i] = M_PI * rand01() / (nf1 * 2 / 32); // x in [-pi,pi)
            y[i] = M_PI * rand01() / (nf2 * 2 / 32);
        }
    } break;
    }
    for (int i = 0; i < nf1 * nf2; i++) {
        fw[i].real(1.0);
        fw[i].imag(0.0);
    }

    checkCudaErrors(cudaMemcpy(d_x, x, M * sizeof(CUFINUFFT_FLT), cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(d_y, y, M * sizeof(CUFINUFFT_FLT), cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(d_fw, fw, nf1 * nf2 * sizeof(CUCPX), cudaMemcpyHostToDevice));

    CNTime timer;
    timer.restart();
    ier = CUFINUFFT_INTERP2D(nf1, nf2, d_fw, M, d_x, d_y, d_c, dplan);
    if (ier != 0) {
        std::cout << "error: cnufftinterp2d" << std::endl;
        return 0;
    }
    CUFINUFFT_FLT t = timer.elapsedsec();
    printf("[Method %d] %ld U pts to #%d NU pts in %.3g s (\t%.3g NU pts/s)\n", dplan->opts.gpu_method, nf1 * nf2, M, t,
           M / t);
    checkCudaErrors(cudaMemcpy(c, d_c, M * sizeof(CUCPX), cudaMemcpyDeviceToHost));
#ifdef RESULT
    std::cout << "[result-input]" << std::endl;
    for (int j = 0; j < M; j++) {
        printf(" (%2.3g,%2.3g)", c[j].real(), c[j].imag());
        std::cout << std::endl;
    }
    std::cout << std::endl;
#endif

    cudaFreeHost(x);
    cudaFreeHost(y);
    cudaFreeHost(c);
    cudaFreeHost(fw);
    cudaFree(d_x);
    cudaFree(d_y);
    cudaFree(d_c);
    cudaFree(d_fw);
    return 0;
}
