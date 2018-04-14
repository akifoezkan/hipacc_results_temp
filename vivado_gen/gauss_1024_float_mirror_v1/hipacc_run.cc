#define HIPACC_MAX_WIDTH     1024
#define HIPACC_MAX_HEIGHT    1024
#define HIPACC_WINDOW_SIZE_X 5
#define HIPACC_WINDOW_SIZE_Y 5
#define BORDER_FILL_VALUE    0
#define HIPACC_II_TARGET     1
#define HIPACC_PPT           1

#include "hipacc_vivado_types.hpp"
#include "hipacc_vivado_filter.hpp"

#include "ccGaussianFilterG.cc"

void hipaccRun(hls::stream<float > &_strmOut0, hls::stream<float > &_strmIN) {
#pragma HLS dataflow
  ccGaussianFilterGKernel(_strmOut0, _strmIN, HIPACC_MAX_WIDTH, HIPACC_MAX_HEIGHT);
}

