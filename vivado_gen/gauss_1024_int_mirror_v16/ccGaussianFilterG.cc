#ifndef _CCGAUSSIANFILTERG_CC_
#define _CCGAUSSIANFILTERG_CC_


struct ccGaussianFilterGKernelKernel {

  ccGaussianFilterGKernelKernel() {
  }

  int operator()(int Input[5][5]) {
    {
        int sum = 0;
        int _tmp0 = 0;
        {
            _tmp0 += 729 * getWindowAt(Input, 0, 0);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 1, 0);
        }
        {
            _tmp0 += 1809 * getWindowAt(Input, 2, 0);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 3, 0);
        }
        {
            _tmp0 += 729 * getWindowAt(Input, 4, 0);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 0, 1);
        }
        {
            _tmp0 += 2916 * getWindowAt(Input, 1, 1);
        }
        {
            _tmp0 += 3618 * getWindowAt(Input, 2, 1);
        }
        {
            _tmp0 += 2916 * getWindowAt(Input, 3, 1);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 4, 1);
        }
        {
            _tmp0 += 1809 * getWindowAt(Input, 0, 2);
        }
        {
            _tmp0 += 3618 * getWindowAt(Input, 1, 2);
        }
        {
            _tmp0 += 4489 * getWindowAt(Input, 2, 2);
        }
        {
            _tmp0 += 3618 * getWindowAt(Input, 3, 2);
        }
        {
            _tmp0 += 1809 * getWindowAt(Input, 4, 2);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 0, 3);
        }
        {
            _tmp0 += 2916 * getWindowAt(Input, 1, 3);
        }
        {
            _tmp0 += 3618 * getWindowAt(Input, 2, 3);
        }
        {
            _tmp0 += 2916 * getWindowAt(Input, 3, 3);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 4, 3);
        }
        {
            _tmp0 += 729 * getWindowAt(Input, 0, 4);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 1, 4);
        }
        {
            _tmp0 += 1809 * getWindowAt(Input, 2, 4);
        }
        {
            _tmp0 += 1458 * getWindowAt(Input, 3, 4);
        }
        {
            _tmp0 += 729 * getWindowAt(Input, 4, 4);
        }
        sum = _tmp0;
        return sum >> 16;
    }
}
};

void ccGaussianFilterGKernel(hls::stream<ap_uint<512> > &Output, hls::stream<ap_uint<512> > &Input, int IS_width, int IS_height) {
    struct ccGaussianFilterGKernelKernel kernel;
    processVECT<HIPACC_II_TARGET,HIPACC_MAX_WIDTH,HIPACC_MAX_HEIGHT,5,5,HIPACC_PPT,int >(Input, Output, IS_width, IS_height, kernel, BorderPadding::BORDER_MIRROR);
}

#endif //_CCGAUSSIANFILTERG_CC_

