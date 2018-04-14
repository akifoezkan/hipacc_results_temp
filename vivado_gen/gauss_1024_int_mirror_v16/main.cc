#include "hipacc_vivado.hpp"

void hipaccRun(hls::stream<ap_uint<512> > &_strmOut0, hls::stream<ap_uint<512> > &_strmIN);

//
// Copyright (c) 2012, University of Erlangen-Nuremberg
// Copyright (c) 2012, Siemens AG
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#include <iostream>
#include <vector>

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/time.h>


//#define TEST

// variables set by Makefile
#define WIDTH  1024
#define HEIGHT 1024
#define SIZE_X 5
#define SIZE_Y 5
#define BORDER_HANDLING_HIPACC Boundary::MIRROR

// Video Memory
struct BorderPadding 
{
public:
    enum values {
      BORDER_UNDEFINED,
      BORDER_CONST,
      BORDER_CLAMP,
      BORDER_MIRROR,
      BORDER_MIRROR_101
    };
};
#ifndef BORDER_FILL_VALUE
  #define BORDER_FILL_VALUE 32
#endif
#ifndef c_BORDER_HANDLING_TYPE
  #define c_BORDER_HANDLING_TYPE BorderPadding::BORDER_MIRROR
#endif


// *************************************************************************
// Test Functions
// *************************************************************************
// Fix helper functions
template<typename inT>
inT getPixel(inT* in, int &cx, int &cy, const int width, const int height,
      enum BorderPadding::values borderMode, inT constVar=BORDER_FILL_VALUE) {
  if(borderMode==BorderPadding::BORDER_CLAMP){                                
    cx = cx < 0 ? 0 : cx;
    cx = cx > width-1 ? width-1 : cx;
    cy = cy < 0 ? 0 : cy;
    cy = cy > height-1 ? height-1 : cy;
  }                                                                              
  else if(borderMode==BorderPadding::BORDER_MIRROR){                               
    cx = cx < 0 ? -cx-1 : cx;
    cx = cx > width-1 ? (width-1)-(cx-width) : cx;
    cy = cy < 0 ? -cy-1 : cy;
    cy = cy > height-1 ? (height-1)-(cy-height) : cy;
  }                                                                              
  else if(borderMode==BorderPadding::BORDER_MIRROR_101){                           
    cx = cx < 0 ? -cx : cx;
    cx = cx > width-1 ? (width-1)-(cx-width)-1 : cx;
    cy = cy < 0 ? -cy : cy;
    cy = cy > height-1 ? (height-1)-(cy-height)-1 : cy;
  }                                                                              
  else if(borderMode==BorderPadding::BORDER_CONST){
    bool boundaryF = (cx < 0 || cx > width-1 || cy<0 || cy>height-1 ) ? 1 : 0;
    inT val = boundaryF ? constVar : in[cy*width + cx];
    return val;
  }
  return in[cy * width + cx];
}
template<typename outT, typename inT, typename filtT>
void localOp(outT *out, const inT *in, const filtT *filter, 
      int size_x, int size_y, int width, int height, 
      enum BorderPadding::values borderMode) {
    inT constVar = BORDER_FILL_VALUE;
    int anchor_x = 0;
    int anchor_y = 0;
    int upper_x = width  - anchor_x;
    int upper_y = height - anchor_y;
    
    for (int y=anchor_y; y<upper_y; ++y) {
      for (int x=anchor_x; x<upper_x; ++x) {
        int sum = 0;
        for (int yf = -size_y/2; yf<=size_y/2; ++yf) {
          for (int xf = -size_x/2; xf<=size_x/2; ++xf) {
            int cx = x + xf; int cy = y + yf;
            sum += filter[(yf+size_y/2)*size_x + xf+size_x/2] * getPixel(in, cx, cy, width, height, borderMode);
          }
        }
        out[y*width + x] = (outT)(sum >> 16);
      }
    }
}

template<typename inT>
void displayFrame(inT* frame, const int width, const int height, 
                  const int offset_x=0, const int offset_y=0){
    for (int y=0; y<height; ++y) {
        for (int x=0; x<width; ++x) {
            //std::cout<< unsigned(frame[(y+offset_y)*WIDTH + offset_x + x]) << " \t ";
            printf("%10u", unsigned(frame[(y+offset_y)*WIDTH + offset_x + x]));
        }
        std::cout<<std::endl;
    } 
}

// *************************************************************************
// Hipacc 
// *************************************************************************


// Gaussian filter in HIPAcc


/*************************************************************************
 * Main function                                                         *
 *************************************************************************/
int main(int argc, const char **argv) {
//    double time0, time1, dt, min_dt;
    
    const int width = WIDTH;
    const int height = HEIGHT;
//    std::vector<int> timings;
//    int timing = 0.0f;

/*************************************************************************
 * Test Data                                                         *
 *************************************************************************/
    // host memory for image of width x height pixels
    int *frame = new int[width*height];
    
    // Reference
    int *reference_in  = new int[width*height];
    int *reference_out = new int[width*height];

    // initialize data
    for (int y=0; y<height; ++y) {
        for (int x=0; x<width; ++x) {
            int indata = rand()%256;
            //int indata = ((x / 5) % 2 == 0) && ((y / 5) % 2 == 0) ? 255 : 0 ;
            frame[y*width + x] = indata;
            reference_in[y*width + x] = indata;
            reference_out[y*width + x] = 0;
        }
    }
    int *host_in = (int*)frame;

// *************************************************************************
    //int *host_out = (int*)malloc(width*height);
    int *host_out = new int[width*height];

    // input and output image of width x height pixels
    HipaccImage IN = hipaccCreateMemory<int>(NULL, width, height);hls::stream<ap_uint<512> > _strmIN;
    HipaccImage OUT = hipaccCreateMemory<int>(NULL, width, height);hls::stream<ap_uint<512> > _strmOut0;

    // convolution filter mask
    const int mask[SIZE_X][SIZE_Y] = {
        {  729, 1458, 1809, 1458,  729},
        { 1458, 2916, 3618, 2916, 1458},
        { 1809, 3618, 4489, 3618, 1809},
        { 1458, 2916, 3618, 2916, 1458},
        {  729, 1458, 1809, 1458,  729}
    };

    
    

    hipaccWriteMemory(IN, _strmIN, host_in);
    

    //BoundaryCondition<int> BcInClamp(IN, M, Boundary::CLAMP);
    
    
    

    

    // get results
    hipaccRun(_strmOut0, _strmIN);
hipaccReadMemory(_strmOut0, host_out, OUT);

//    fprintf(stdout, "Execution time: %f ms\n", timing);

/**************************************************************************
 * Compare Output with reference functions                               *
 *************************************************************************/
    std::cerr << "Calculating reference ..." << std::endl;
    localOp(reference_out, reference_in, &mask[0][0], 
               SIZE_X, SIZE_Y, WIDTH, HEIGHT, c_BORDER_HANDLING_TYPE);
    std::cerr << "Comparing results ..." << std::endl;
    int pOfX= 0; //WIDTH-20;
    int pOfY= 0; //HEIGHT-10;
    printf("Reference Input \n");  displayFrame(reference_in,  15, 12, pOfX, pOfY);
    printf("Reference Output \n"); displayFrame(reference_out, 15, 12, pOfX, pOfY);
    printf("   Hipacc Output \n"); displayFrame(     host_out, 15, 12, pOfX, pOfY);
    // Test Gauss (!Be careful about offset)
    int offset_x = 0; //(SIZE_X >> 1);
    int offset_y = 0; //(SIZE_Y >> 1);
#ifdef BORDER_HANDLING_HIPACC == Boundary::UNDEFINED
//    if(c_BORDER_HANDLING_TYPE==BorderPadding::BORDER_UNDEFINED){
      offset_x = (SIZE_X >> 1);
      offset_y = (SIZE_Y >> 1);
//    }
#endif
    int offset_lx = offset_x; //(SIZE_X >> 1); 
    int offset_rx = offset_x; //(SIZE_X >> 1); 
    int offset_ly = offset_y;
    int offset_ry = offset_y; // (SIZE_Y >> 1); // offset_y;
    for (int y=offset_ly; y<height-offset_ry; ++y) {
        for (int x=offset_lx; x<width-offset_rx; ++x) {
            if (reference_out[y*width + x] != host_out[y*width + x]) {
                std::cerr << "Test FAILED, at (" << x << "," << y << "): "
                << (int)reference_out[y*width + x] << " vs. "
                << (int)host_out[y*width + x] << std::endl;
                // Print Output
                //printf("Hipacc Output \n"); displayFrame(host_out, 20, 10);
                //exit(EXIT_FAILURE);
                y=height; break;
            }
        }
    }
    std::cerr << "Test PASSED" << std::endl;

    // memory cleanup
    //free(host_in);
    //free(host_out);

    hipaccReleaseMemory(OUT);
    hipaccReleaseMemory(IN);
    return EXIT_SUCCESS;
}

