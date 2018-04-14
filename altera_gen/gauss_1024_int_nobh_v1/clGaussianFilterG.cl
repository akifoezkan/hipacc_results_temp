#ifndef _CLGAUSSIANFILTERG_CL_
#define _CLGAUSSIANFILTERG_CL_


int clGaussianFilterGKernelKernel(int Input[5][5]) {
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


__kernel __attribute__((reqd_work_group_size(1, 1, 1)))
 void clGaussianFilterGKernel(__global int * restrict OUT, __global const int * restrict IN) {
    process(1, int, int, OUT, ARRY, IN, ARRY, HIPACC_MAX_WIDTH, HIPACC_MAX_HEIGHT, clGaussianFilterGKernelKernel, 5, 5, UNDEFINED);
}

#endif //_CLGAUSSIANFILTERG_CL_

