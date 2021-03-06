/*
 * MicroHH
 * Copyright (c) 2011-2017 Chiel van Heerwaarden
 * Copyright (c) 2011-2017 Thijs Heus
 * Copyright (c) 2014-2017 Bart van Stratum
 *
 * This file is part of MicroHH
 *
 * MicroHH is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * MicroHH is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with MicroHH.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <cmath>
#include "advec_4.h"
#include "grid.h"
#include "fields.h"
#include "defines.h"
#include "finite_difference.h"
#include "tools.h"
#include "constants.h"

using namespace Finite_difference::O4;

namespace
{
    __global__ 
    void advec_u_g(double* __restrict__ ut, double* __restrict__ u, 
                   double* __restrict__ v,  double* __restrict__ w,
                   double* __restrict__ dzi4, double dxi, double dyi, 
                   int jj, int kk,
                   int istart, int jstart, int kstart,
                   int iend,   int jend,   int kend)
        {
            const int i = blockIdx.x*blockDim.x + threadIdx.x + istart;
            const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart;
            const int k = blockIdx.z + kstart;

            const int ii1 = 1;
            const int ii2 = 2;
            const int ii3 = 3;
            const int jj1 = 1*jj;
            const int jj2 = 2*jj;
            const int jj3 = 3*jj;
            const int kk1 = 1*kk;
            const int kk2 = 2*kk;
            const int kk3 = 3*kk;

            if (i < iend && j < jend && k > kstart && k < kend-1)
            {
                const int ijk = i + j*jj + k*kk;
                ut[ijk] -= ( cg0*((ci0*u[ijk-ii3] + ci1*u[ijk-ii2] + ci2*u[ijk-ii1] + ci3*u[ijk    ]) * (ci0*u[ijk-ii3] + ci1*u[ijk-ii2] + ci2*u[ijk-ii1] + ci3*u[ijk    ]))
                           + cg1*((ci0*u[ijk-ii2] + ci1*u[ijk-ii1] + ci2*u[ijk    ] + ci3*u[ijk+ii1]) * (ci0*u[ijk-ii2] + ci1*u[ijk-ii1] + ci2*u[ijk    ] + ci3*u[ijk+ii1]))
                           + cg2*((ci0*u[ijk-ii1] + ci1*u[ijk    ] + ci2*u[ijk+ii1] + ci3*u[ijk+ii2]) * (ci0*u[ijk-ii1] + ci1*u[ijk    ] + ci2*u[ijk+ii1] + ci3*u[ijk+ii2]))
                           + cg3*((ci0*u[ijk    ] + ci1*u[ijk+ii1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii3]) * (ci0*u[ijk    ] + ci1*u[ijk+ii1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii3])) ) * cgi*dxi;

                ut[ijk] -= ( cg0*((ci0*v[ijk-ii2-jj1] + ci1*v[ijk-ii1-jj1] + ci2*v[ijk-jj1] + ci3*v[ijk+ii1-jj1]) * (ci0*u[ijk-jj3] + ci1*u[ijk-jj2] + ci2*u[ijk-jj1] + ci3*u[ijk    ]))
                           + cg1*((ci0*v[ijk-ii2    ] + ci1*v[ijk-ii1    ] + ci2*v[ijk    ] + ci3*v[ijk+ii1    ]) * (ci0*u[ijk-jj2] + ci1*u[ijk-jj1] + ci2*u[ijk    ] + ci3*u[ijk+jj1]))
                           + cg2*((ci0*v[ijk-ii2+jj1] + ci1*v[ijk-ii1+jj1] + ci2*v[ijk+jj1] + ci3*v[ijk+ii1+jj1]) * (ci0*u[ijk-jj1] + ci1*u[ijk    ] + ci2*u[ijk+jj1] + ci3*u[ijk+jj2]))
                           + cg3*((ci0*v[ijk-ii2+jj2] + ci1*v[ijk-ii1+jj2] + ci2*v[ijk+jj2] + ci3*v[ijk+ii1+jj2]) * (ci0*u[ijk    ] + ci1*u[ijk+jj1] + ci2*u[ijk+jj2] + ci3*u[ijk+jj3])) ) * cgi*dyi;

                ut[ijk] -= ( cg0*((ci0*w[ijk-ii2-kk1] + ci1*w[ijk-ii1-kk1] + ci2*w[ijk-kk1] + ci3*w[ijk+ii1-kk1]) * (ci0*u[ijk-kk3] + ci1*u[ijk-kk2] + ci2*u[ijk-kk1] + ci3*u[ijk    ]))
                           + cg1*((ci0*w[ijk-ii2    ] + ci1*w[ijk-ii1    ] + ci2*w[ijk    ] + ci3*w[ijk+ii1    ]) * (ci0*u[ijk-kk2] + ci1*u[ijk-kk1] + ci2*u[ijk    ] + ci3*u[ijk+kk1]))
                           + cg2*((ci0*w[ijk-ii2+kk1] + ci1*w[ijk-ii1+kk1] + ci2*w[ijk+kk1] + ci3*w[ijk+ii1+kk1]) * (ci0*u[ijk-kk1] + ci1*u[ijk    ] + ci2*u[ijk+kk1] + ci3*u[ijk+kk2]))
                           + cg3*((ci0*w[ijk-ii2+kk2] + ci1*w[ijk-ii1+kk2] + ci2*w[ijk+kk2] + ci3*w[ijk+ii1+kk2]) * (ci0*u[ijk    ] + ci1*u[ijk+kk1] + ci2*u[ijk+kk2] + ci3*u[ijk+kk3])) ) * dzi4[k];
            }
        }

    template<int loc> __global__ 
    void advec_u_boundary_g(double* __restrict__ ut, double* __restrict__ u, 
                            double* __restrict__ v,  double* __restrict__ w,
                            double* __restrict__ dzi4, double dxi, double dyi, 
                            int jj, int kk,
                            int istart, int jstart, int kstart,
                            int iend,   int jend,   int kend)
        {
            const int i = blockIdx.x*blockDim.x + threadIdx.x + istart;
            const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart;

            const int ii1 = 1;
            const int ii2 = 2;
            const int ii3 = 3;
            const int jj1 = 1*jj;
            const int jj2 = 2*jj;
            const int jj3 = 3*jj;
            const int kk1 = 1*kk;
            const int kk2 = 2*kk;
            const int kk3 = 3*kk;

            if (i < iend && j < jend)
            {
                if (loc == 0)
                {
                    const int k = kstart;
                    const int ijk = i + j*jj + k*kk;

                    ut[ijk] -= ( cg0*((ci0*u[ijk-ii3] + ci1*u[ijk-ii2] + ci2*u[ijk-ii1] + ci3*u[ijk    ]) * (ci0*u[ijk-ii3] + ci1*u[ijk-ii2] + ci2*u[ijk-ii1] + ci3*u[ijk    ]))
                               + cg1*((ci0*u[ijk-ii2] + ci1*u[ijk-ii1] + ci2*u[ijk    ] + ci3*u[ijk+ii1]) * (ci0*u[ijk-ii2] + ci1*u[ijk-ii1] + ci2*u[ijk    ] + ci3*u[ijk+ii1]))
                               + cg2*((ci0*u[ijk-ii1] + ci1*u[ijk    ] + ci2*u[ijk+ii1] + ci3*u[ijk+ii2]) * (ci0*u[ijk-ii1] + ci1*u[ijk    ] + ci2*u[ijk+ii1] + ci3*u[ijk+ii2]))
                               + cg3*((ci0*u[ijk    ] + ci1*u[ijk+ii1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii3]) * (ci0*u[ijk    ] + ci1*u[ijk+ii1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii3])) ) * cgi*dxi;

                    ut[ijk] -= ( cg0*((ci0*v[ijk-ii2-jj1] + ci1*v[ijk-ii1-jj1] + ci2*v[ijk-jj1] + ci3*v[ijk+ii1-jj1]) * (ci0*u[ijk-jj3] + ci1*u[ijk-jj2] + ci2*u[ijk-jj1] + ci3*u[ijk    ]))
                               + cg1*((ci0*v[ijk-ii2    ] + ci1*v[ijk-ii1    ] + ci2*v[ijk    ] + ci3*v[ijk+ii1    ]) * (ci0*u[ijk-jj2] + ci1*u[ijk-jj1] + ci2*u[ijk    ] + ci3*u[ijk+jj1]))
                               + cg2*((ci0*v[ijk-ii2+jj1] + ci1*v[ijk-ii1+jj1] + ci2*v[ijk+jj1] + ci3*v[ijk+ii1+jj1]) * (ci0*u[ijk-jj1] + ci1*u[ijk    ] + ci2*u[ijk+jj1] + ci3*u[ijk+jj2]))
                               + cg3*((ci0*v[ijk-ii2+jj2] + ci1*v[ijk-ii1+jj2] + ci2*v[ijk+jj2] + ci3*v[ijk+ii1+jj2]) * (ci0*u[ijk    ] + ci1*u[ijk+jj1] + ci2*u[ijk+jj2] + ci3*u[ijk+jj3])) ) * cgi*dyi;

                    ut[ijk] -= ( cg0*((ci0*w[ijk-ii2-kk1] + ci1*w[ijk-ii1-kk1] + ci2*w[ijk-kk1] + ci3*w[ijk+ii1-kk1]) * (bi0*u[ijk-kk2] + bi1*u[ijk-kk1] + bi2*u[ijk    ] + bi3*u[ijk+kk1]))
                               + cg1*((ci0*w[ijk-ii2    ] + ci1*w[ijk-ii1    ] + ci2*w[ijk    ] + ci3*w[ijk+ii1    ]) * (ci0*u[ijk-kk2] + ci1*u[ijk-kk1] + ci2*u[ijk    ] + ci3*u[ijk+kk1]))
                               + cg2*((ci0*w[ijk-ii2+kk1] + ci1*w[ijk-ii1+kk1] + ci2*w[ijk+kk1] + ci3*w[ijk+ii1+kk1]) * (ci0*u[ijk-kk1] + ci1*u[ijk    ] + ci2*u[ijk+kk1] + ci3*u[ijk+kk2]))
                               + cg3*((ci0*w[ijk-ii2+kk2] + ci1*w[ijk-ii1+kk2] + ci2*w[ijk+kk2] + ci3*w[ijk+ii1+kk2]) * (ci0*u[ijk    ] + ci1*u[ijk+kk1] + ci2*u[ijk+kk2] + ci3*u[ijk+kk3])) ) * dzi4[k];
                }
                else if (loc == 1)
                {
                    const int k = kend-1;
                    const int ijk = i + j*jj + k*kk;

                    ut[ijk] -= ( cg0*((ci0*u[ijk-ii3] + ci1*u[ijk-ii2] + ci2*u[ijk-ii1] + ci3*u[ijk    ]) * (ci0*u[ijk-ii3] + ci1*u[ijk-ii2] + ci2*u[ijk-ii1] + ci3*u[ijk    ]))
                               + cg1*((ci0*u[ijk-ii2] + ci1*u[ijk-ii1] + ci2*u[ijk    ] + ci3*u[ijk+ii1]) * (ci0*u[ijk-ii2] + ci1*u[ijk-ii1] + ci2*u[ijk    ] + ci3*u[ijk+ii1]))
                               + cg2*((ci0*u[ijk-ii1] + ci1*u[ijk    ] + ci2*u[ijk+ii1] + ci3*u[ijk+ii2]) * (ci0*u[ijk-ii1] + ci1*u[ijk    ] + ci2*u[ijk+ii1] + ci3*u[ijk+ii2]))
                               + cg3*((ci0*u[ijk    ] + ci1*u[ijk+ii1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii3]) * (ci0*u[ijk    ] + ci1*u[ijk+ii1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii3])) ) * cgi*dxi;

                    ut[ijk] -= ( cg0*((ci0*v[ijk-ii2-jj1] + ci1*v[ijk-ii1-jj1] + ci2*v[ijk-jj1] + ci3*v[ijk+ii1-jj1]) * (ci0*u[ijk-jj3] + ci1*u[ijk-jj2] + ci2*u[ijk-jj1] + ci3*u[ijk    ]))
                               + cg1*((ci0*v[ijk-ii2    ] + ci1*v[ijk-ii1    ] + ci2*v[ijk    ] + ci3*v[ijk+ii1    ]) * (ci0*u[ijk-jj2] + ci1*u[ijk-jj1] + ci2*u[ijk    ] + ci3*u[ijk+jj1]))
                               + cg2*((ci0*v[ijk-ii2+jj1] + ci1*v[ijk-ii1+jj1] + ci2*v[ijk+jj1] + ci3*v[ijk+ii1+jj1]) * (ci0*u[ijk-jj1] + ci1*u[ijk    ] + ci2*u[ijk+jj1] + ci3*u[ijk+jj2]))
                               + cg3*((ci0*v[ijk-ii2+jj2] + ci1*v[ijk-ii1+jj2] + ci2*v[ijk+jj2] + ci3*v[ijk+ii1+jj2]) * (ci0*u[ijk    ] + ci1*u[ijk+jj1] + ci2*u[ijk+jj2] + ci3*u[ijk+jj3])) ) * cgi*dyi;

                    ut[ijk] -= ( cg0*((ci0*w[ijk-ii2-kk1] + ci1*w[ijk-ii1-kk1] + ci2*w[ijk-kk1] + ci3*w[ijk+ii1-kk1]) * (ci0*u[ijk-kk3] + ci1*u[ijk-kk2] + ci2*u[ijk-kk1] + ci3*u[ijk    ]))
                               + cg1*((ci0*w[ijk-ii2    ] + ci1*w[ijk-ii1    ] + ci2*w[ijk    ] + ci3*w[ijk+ii1    ]) * (ci0*u[ijk-kk2] + ci1*u[ijk-kk1] + ci2*u[ijk    ] + ci3*u[ijk+kk1]))
                               + cg2*((ci0*w[ijk-ii2+kk1] + ci1*w[ijk-ii1+kk1] + ci2*w[ijk+kk1] + ci3*w[ijk+ii1+kk1]) * (ci0*u[ijk-kk1] + ci1*u[ijk    ] + ci2*u[ijk+kk1] + ci3*u[ijk+kk2]))
                               + cg3*((ci0*w[ijk-ii2+kk2] + ci1*w[ijk-ii1+kk2] + ci2*w[ijk+kk2] + ci3*w[ijk+ii1+kk2]) * (ti0*u[ijk-kk1] + ti1*u[ijk    ] + ti2*u[ijk+kk1] + ti3*u[ijk+kk2])) ) * dzi4[k];
                }
            }
        }


    __global__ 
    void advec_v_g(double* __restrict__ vt, double* __restrict__ u, 
                   double* __restrict__ v,  double* __restrict__ w,
                   double* __restrict__ dzi4, double dxi, double dyi, 
                   int jj, int kk,
                   int istart, int jstart, int kstart,
                   int iend,   int jend,   int kend)
    {
        const int i = blockIdx.x*blockDim.x + threadIdx.x + istart;
        const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart;
        const int k = blockIdx.z + kstart;

        const int ii1 = 1;
        const int ii2 = 2;
        const int ii3 = 3;
        const int jj1 = 1*jj;
        const int jj2 = 2*jj;
        const int jj3 = 3*jj;
        const int kk1 = 1*kk;
        const int kk2 = 2*kk;
        const int kk3 = 3*kk;

        if (i < iend && j < jend && k > kstart && k < kend-1)
        {
            const int ijk = i + j*jj + k*kk;

            vt[ijk] -= ( cg0*((ci0*u[ijk-ii1-jj2] + ci1*u[ijk-ii1-jj1] + ci2*u[ijk-ii1] + ci3*u[ijk-ii1+jj1]) * (ci0*v[ijk-ii3] + ci1*v[ijk-ii2] + ci2*v[ijk-ii1] + ci3*v[ijk    ]))
                       + cg1*((ci0*u[ijk    -jj2] + ci1*u[ijk    -jj1] + ci2*u[ijk    ] + ci3*u[ijk    +jj1]) * (ci0*v[ijk-ii2] + ci1*v[ijk-ii1] + ci2*v[ijk    ] + ci3*v[ijk+ii1]))
                       + cg2*((ci0*u[ijk+ii1-jj2] + ci1*u[ijk+ii1-jj1] + ci2*u[ijk+ii1] + ci3*u[ijk+ii1+jj1]) * (ci0*v[ijk-ii1] + ci1*v[ijk    ] + ci2*v[ijk+ii1] + ci3*v[ijk+ii2]))
                       + cg3*((ci0*u[ijk+ii2-jj2] + ci1*u[ijk+ii2-jj1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii2+jj1]) * (ci0*v[ijk    ] + ci1*v[ijk+ii1] + ci2*v[ijk+ii2] + ci3*v[ijk+ii3])) ) * cgi*dxi;

            vt[ijk] -= ( cg0*((ci0*v[ijk-jj3] + ci1*v[ijk-jj2] + ci2*v[ijk-jj1] + ci3*v[ijk    ]) * (ci0*v[ijk-jj3] + ci1*v[ijk-jj2] + ci2*v[ijk-jj1] + ci3*v[ijk    ]))
                       + cg1*((ci0*v[ijk-jj2] + ci1*v[ijk-jj1] + ci2*v[ijk    ] + ci3*v[ijk+jj1]) * (ci0*v[ijk-jj2] + ci1*v[ijk-jj1] + ci2*v[ijk    ] + ci3*v[ijk+jj1]))
                       + cg2*((ci0*v[ijk-jj1] + ci1*v[ijk    ] + ci2*v[ijk+jj1] + ci3*v[ijk+jj2]) * (ci0*v[ijk-jj1] + ci1*v[ijk    ] + ci2*v[ijk+jj1] + ci3*v[ijk+jj2]))
                       + cg3*((ci0*v[ijk    ] + ci1*v[ijk+jj1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj3]) * (ci0*v[ijk    ] + ci1*v[ijk+jj1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj3])) ) * cgi*dyi;

            vt[ijk] -= ( cg0*((ci0*w[ijk-jj2-kk1] + ci1*w[ijk-jj1-kk1] + ci2*w[ijk-kk1] + ci3*w[ijk+jj1-kk1]) * (ci0*v[ijk-kk3] + ci1*v[ijk-kk2] + ci2*v[ijk-kk1] + ci3*v[ijk    ]))
                       + cg1*((ci0*w[ijk-jj2    ] + ci1*w[ijk-jj1    ] + ci2*w[ijk    ] + ci3*w[ijk+jj1    ]) * (ci0*v[ijk-kk2] + ci1*v[ijk-kk1] + ci2*v[ijk    ] + ci3*v[ijk+kk1]))
                       + cg2*((ci0*w[ijk-jj2+kk1] + ci1*w[ijk-jj1+kk1] + ci2*w[ijk+kk1] + ci3*w[ijk+jj1+kk1]) * (ci0*v[ijk-kk1] + ci1*v[ijk    ] + ci2*v[ijk+kk1] + ci3*v[ijk+kk2]))
                       + cg3*((ci0*w[ijk-jj2+kk2] + ci1*w[ijk-jj1+kk2] + ci2*w[ijk+kk2] + ci3*w[ijk+jj1+kk2]) * (ci0*v[ijk    ] + ci1*v[ijk+kk1] + ci2*v[ijk+kk2] + ci3*v[ijk+kk3])) ) * dzi4[k];
        }
    }

    template<int loc> __global__ 
    void advec_v_boundary_g(double* __restrict__ vt, double* __restrict__ u, 
                            double* __restrict__ v,  double* __restrict__ w,
                            double* __restrict__ dzi4, double dxi, double dyi, 
                            int jj, int kk,
                            int istart, int jstart, int kstart,
                            int iend,   int jend,   int kend)
        {
            const int i = blockIdx.x*blockDim.x + threadIdx.x + istart;
            const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart;

            const int ii1 = 1;
            const int ii2 = 2;
            const int ii3 = 3;
            const int jj1 = 1*jj;
            const int jj2 = 2*jj;
            const int jj3 = 3*jj;
            const int kk1 = 1*kk;
            const int kk2 = 2*kk;
            const int kk3 = 3*kk;

            if (i < iend && j < jend)
            {
                if (loc == 0)
                {
                    const int k = kstart;
                    const int ijk = i + j*jj + k*kk;

                    vt[ijk] -= ( cg0*((ci0*u[ijk-ii1-jj2] + ci1*u[ijk-ii1-jj1] + ci2*u[ijk-ii1] + ci3*u[ijk-ii1+jj1]) * (ci0*v[ijk-ii3] + ci1*v[ijk-ii2] + ci2*v[ijk-ii1] + ci3*v[ijk    ]))
                               + cg1*((ci0*u[ijk    -jj2] + ci1*u[ijk    -jj1] + ci2*u[ijk    ] + ci3*u[ijk    +jj1]) * (ci0*v[ijk-ii2] + ci1*v[ijk-ii1] + ci2*v[ijk    ] + ci3*v[ijk+ii1]))
                               + cg2*((ci0*u[ijk+ii1-jj2] + ci1*u[ijk+ii1-jj1] + ci2*u[ijk+ii1] + ci3*u[ijk+ii1+jj1]) * (ci0*v[ijk-ii1] + ci1*v[ijk    ] + ci2*v[ijk+ii1] + ci3*v[ijk+ii2]))
                               + cg3*((ci0*u[ijk+ii2-jj2] + ci1*u[ijk+ii2-jj1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii2+jj1]) * (ci0*v[ijk    ] + ci1*v[ijk+ii1] + ci2*v[ijk+ii2] + ci3*v[ijk+ii3])) ) * cgi*dxi;

                    vt[ijk] -= ( cg0*((ci0*v[ijk-jj3] + ci1*v[ijk-jj2] + ci2*v[ijk-jj1] + ci3*v[ijk    ]) * (ci0*v[ijk-jj3] + ci1*v[ijk-jj2] + ci2*v[ijk-jj1] + ci3*v[ijk    ]))
                               + cg1*((ci0*v[ijk-jj2] + ci1*v[ijk-jj1] + ci2*v[ijk    ] + ci3*v[ijk+jj1]) * (ci0*v[ijk-jj2] + ci1*v[ijk-jj1] + ci2*v[ijk    ] + ci3*v[ijk+jj1]))
                               + cg2*((ci0*v[ijk-jj1] + ci1*v[ijk    ] + ci2*v[ijk+jj1] + ci3*v[ijk+jj2]) * (ci0*v[ijk-jj1] + ci1*v[ijk    ] + ci2*v[ijk+jj1] + ci3*v[ijk+jj2]))
                               + cg3*((ci0*v[ijk    ] + ci1*v[ijk+jj1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj3]) * (ci0*v[ijk    ] + ci1*v[ijk+jj1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj3])) ) * cgi*dyi;

                    vt[ijk] -= ( cg0*((ci0*w[ijk-jj2-kk1] + ci1*w[ijk-jj1-kk1] + ci2*w[ijk-kk1] + ci3*w[ijk+jj1-kk1]) * (bi0*v[ijk-kk2] + bi1*v[ijk-kk1] + bi2*v[ijk    ] + bi3*v[ijk+kk1]))
                               + cg1*((ci0*w[ijk-jj2    ] + ci1*w[ijk-jj1    ] + ci2*w[ijk    ] + ci3*w[ijk+jj1    ]) * (ci0*v[ijk-kk2] + ci1*v[ijk-kk1] + ci2*v[ijk    ] + ci3*v[ijk+kk1]))
                               + cg2*((ci0*w[ijk-jj2+kk1] + ci1*w[ijk-jj1+kk1] + ci2*w[ijk+kk1] + ci3*w[ijk+jj1+kk1]) * (ci0*v[ijk-kk1] + ci1*v[ijk    ] + ci2*v[ijk+kk1] + ci3*v[ijk+kk2]))
                               + cg3*((ci0*w[ijk-jj2+kk2] + ci1*w[ijk-jj1+kk2] + ci2*w[ijk+kk2] + ci3*w[ijk+jj1+kk2]) * (ci0*v[ijk    ] + ci1*v[ijk+kk1] + ci2*v[ijk+kk2] + ci3*v[ijk+kk3])) ) * dzi4[k];
                }
                else if (loc == 1)
                {
                    const int k = kend-1;
                    const int ijk = i + j*jj + k*kk;

                    vt[ijk] -= ( cg0*((ci0*u[ijk-ii1-jj2] + ci1*u[ijk-ii1-jj1] + ci2*u[ijk-ii1] + ci3*u[ijk-ii1+jj1]) * (ci0*v[ijk-ii3] + ci1*v[ijk-ii2] + ci2*v[ijk-ii1] + ci3*v[ijk    ]))
                               + cg1*((ci0*u[ijk    -jj2] + ci1*u[ijk    -jj1] + ci2*u[ijk    ] + ci3*u[ijk    +jj1]) * (ci0*v[ijk-ii2] + ci1*v[ijk-ii1] + ci2*v[ijk    ] + ci3*v[ijk+ii1]))
                               + cg2*((ci0*u[ijk+ii1-jj2] + ci1*u[ijk+ii1-jj1] + ci2*u[ijk+ii1] + ci3*u[ijk+ii1+jj1]) * (ci0*v[ijk-ii1] + ci1*v[ijk    ] + ci2*v[ijk+ii1] + ci3*v[ijk+ii2]))
                               + cg3*((ci0*u[ijk+ii2-jj2] + ci1*u[ijk+ii2-jj1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii2+jj1]) * (ci0*v[ijk    ] + ci1*v[ijk+ii1] + ci2*v[ijk+ii2] + ci3*v[ijk+ii3])) ) * cgi*dxi;

                    vt[ijk] -= ( cg0*((ci0*v[ijk-jj3] + ci1*v[ijk-jj2] + ci2*v[ijk-jj1] + ci3*v[ijk    ]) * (ci0*v[ijk-jj3] + ci1*v[ijk-jj2] + ci2*v[ijk-jj1] + ci3*v[ijk    ]))
                               + cg1*((ci0*v[ijk-jj2] + ci1*v[ijk-jj1] + ci2*v[ijk    ] + ci3*v[ijk+jj1]) * (ci0*v[ijk-jj2] + ci1*v[ijk-jj1] + ci2*v[ijk    ] + ci3*v[ijk+jj1]))
                               + cg2*((ci0*v[ijk-jj1] + ci1*v[ijk    ] + ci2*v[ijk+jj1] + ci3*v[ijk+jj2]) * (ci0*v[ijk-jj1] + ci1*v[ijk    ] + ci2*v[ijk+jj1] + ci3*v[ijk+jj2]))
                               + cg3*((ci0*v[ijk    ] + ci1*v[ijk+jj1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj3]) * (ci0*v[ijk    ] + ci1*v[ijk+jj1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj3])) ) * cgi*dyi;

                    vt[ijk] -= ( cg0*((ci0*w[ijk-jj2-kk1] + ci1*w[ijk-jj1-kk1] + ci2*w[ijk-kk1] + ci3*w[ijk+jj1-kk1]) * (ci0*v[ijk-kk3] + ci1*v[ijk-kk2] + ci2*v[ijk-kk1] + ci3*v[ijk    ]))
                               + cg1*((ci0*w[ijk-jj2    ] + ci1*w[ijk-jj1    ] + ci2*w[ijk    ] + ci3*w[ijk+jj1    ]) * (ci0*v[ijk-kk2] + ci1*v[ijk-kk1] + ci2*v[ijk    ] + ci3*v[ijk+kk1]))
                               + cg2*((ci0*w[ijk-jj2+kk1] + ci1*w[ijk-jj1+kk1] + ci2*w[ijk+kk1] + ci3*w[ijk+jj1+kk1]) * (ci0*v[ijk-kk1] + ci1*v[ijk    ] + ci2*v[ijk+kk1] + ci3*v[ijk+kk2]))
                               + cg3*((ci0*w[ijk-jj2+kk2] + ci1*w[ijk-jj1+kk2] + ci2*w[ijk+kk2] + ci3*w[ijk+jj1+kk2]) * (ti0*v[ijk-kk1] + ti1*v[ijk    ] + ti2*v[ijk+kk1] + ti3*v[ijk+kk2])) ) * dzi4[k];
                }
            }
        }

    __global__ 
    void advec_w_g(double* __restrict__ wt, double* __restrict__ u, 
                   double* __restrict__ v,  double* __restrict__ w,
                   double* __restrict__ dzhi4, double dxi, double dyi, 
                   int jj, int kk, 
                   int istart, int jstart, int kstart,
                   int iend,   int jend,   int kend)
    {
        const int i = blockIdx.x*blockDim.x + threadIdx.x + istart;
        const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart;
        const int k = blockIdx.z + kstart + 1;

        const int ii1 = 1;
        const int ii2 = 2;
        const int ii3 = 3;
        const int jj1 = 1*jj;
        const int jj2 = 2*jj;
        const int jj3 = 3*jj;
        const int kk1 = 1*kk;
        const int kk2 = 2*kk;
        const int kk3 = 3*kk;

        if(i < iend && j < jend && k > kstart+1 && k < kend-1)
        {
            const int ijk = i + j*jj + k*kk;

            wt[ijk] -= ( cg0*((ci0*u[ijk-ii1-kk2] + ci1*u[ijk-ii1-kk1] + ci2*u[ijk-ii1] + ci3*u[ijk-ii1+kk1]) * (ci0*w[ijk-ii3] + ci1*w[ijk-ii2] + ci2*w[ijk-ii1] + ci3*w[ijk    ]))
                       + cg1*((ci0*u[ijk    -kk2] + ci1*u[ijk    -kk1] + ci2*u[ijk    ] + ci3*u[ijk    +kk1]) * (ci0*w[ijk-ii2] + ci1*w[ijk-ii1] + ci2*w[ijk    ] + ci3*w[ijk+ii1]))
                       + cg2*((ci0*u[ijk+ii1-kk2] + ci1*u[ijk+ii1-kk1] + ci2*u[ijk+ii1] + ci3*u[ijk+ii1+kk1]) * (ci0*w[ijk-ii1] + ci1*w[ijk    ] + ci2*w[ijk+ii1] + ci3*w[ijk+ii2]))
                       + cg3*((ci0*u[ijk+ii2-kk2] + ci1*u[ijk+ii2-kk1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii2+kk1]) * (ci0*w[ijk    ] + ci1*w[ijk+ii1] + ci2*w[ijk+ii2] + ci3*w[ijk+ii3])) ) * cgi*dxi;

            wt[ijk] -= ( cg0*((ci0*v[ijk-jj1-kk2] + ci1*v[ijk-jj1-kk1] + ci2*v[ijk-jj1] + ci3*v[ijk-jj1+kk1]) * (ci0*w[ijk-jj3] + ci1*w[ijk-jj2] + ci2*w[ijk-jj1] + ci3*w[ijk    ]))
                       + cg1*((ci0*v[ijk    -kk2] + ci1*v[ijk    -kk1] + ci2*v[ijk    ] + ci3*v[ijk    +kk1]) * (ci0*w[ijk-jj2] + ci1*w[ijk-jj1] + ci2*w[ijk    ] + ci3*w[ijk+jj1]))
                       + cg2*((ci0*v[ijk+jj1-kk2] + ci1*v[ijk+jj1-kk1] + ci2*v[ijk+jj1] + ci3*v[ijk+jj1+kk1]) * (ci0*w[ijk-jj1] + ci1*w[ijk    ] + ci2*w[ijk+jj1] + ci3*w[ijk+jj2]))
                       + cg3*((ci0*v[ijk+jj2-kk2] + ci1*v[ijk+jj2-kk1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj2+kk1]) * (ci0*w[ijk    ] + ci1*w[ijk+jj1] + ci2*w[ijk+jj2] + ci3*w[ijk+jj3])) ) * cgi*dyi;

            wt[ijk] -= ( cg0*((ci0*w[ijk-kk3] + ci1*w[ijk-kk2] + ci2*w[ijk-kk1] + ci3*w[ijk    ]) * (ci0*w[ijk-kk3] + ci1*w[ijk-kk2] + ci2*w[ijk-kk1] + ci3*w[ijk    ]))
                       + cg1*((ci0*w[ijk-kk2] + ci1*w[ijk-kk1] + ci2*w[ijk    ] + ci3*w[ijk+kk1]) * (ci0*w[ijk-kk2] + ci1*w[ijk-kk1] + ci2*w[ijk    ] + ci3*w[ijk+kk1]))
                       + cg2*((ci0*w[ijk-kk1] + ci1*w[ijk    ] + ci2*w[ijk+kk1] + ci3*w[ijk+kk2]) * (ci0*w[ijk-kk1] + ci1*w[ijk    ] + ci2*w[ijk+kk1] + ci3*w[ijk+kk2]))
                       + cg3*((ci0*w[ijk    ] + ci1*w[ijk+kk1] + ci2*w[ijk+kk2] + ci3*w[ijk+kk3]) * (ci0*w[ijk    ] + ci1*w[ijk+kk1] + ci2*w[ijk+kk2] + ci3*w[ijk+kk3])) ) * dzhi4[k];
        }
    }

    template<int loc> __global__ 
    void advec_w_boundary_g(double* __restrict__ wt, double* __restrict__ u, 
                            double* __restrict__ v,  double* __restrict__ w,
                            double* __restrict__ dzhi4, double dxi, double dyi, 
                            int jj, int kk, 
                            int istart, int jstart, int kstart,
                            int iend,   int jend,   int kend)
        {
            const int i = blockIdx.x*blockDim.x + threadIdx.x + istart;
            const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart;

            const int ii1 = 1;
            const int ii2 = 2;
            const int ii3 = 3;
            const int jj1 = 1*jj;
            const int jj2 = 2*jj;
            const int jj3 = 3*jj;
            const int kk1 = 1*kk;
            const int kk2 = 2*kk;
            const int kk3 = 3*kk;

            if (i < iend && j < jend)
            {
                if (loc == 0) //== kstart+1
                {
                    const int k = kstart+1;
                    const int ijk = i + j*jj + k*kk;

                    wt[ijk] -= ( cg0*((ci0*u[ijk-ii1-kk2] + ci1*u[ijk-ii1-kk1] + ci2*u[ijk-ii1] + ci3*u[ijk-ii1+kk1]) * (ci0*w[ijk-ii3] + ci1*w[ijk-ii2] + ci2*w[ijk-ii1] + ci3*w[ijk    ]))
                               + cg1*((ci0*u[ijk    -kk2] + ci1*u[ijk    -kk1] + ci2*u[ijk    ] + ci3*u[ijk    +kk1]) * (ci0*w[ijk-ii2] + ci1*w[ijk-ii1] + ci2*w[ijk    ] + ci3*w[ijk+ii1]))
                               + cg2*((ci0*u[ijk+ii1-kk2] + ci1*u[ijk+ii1-kk1] + ci2*u[ijk+ii1] + ci3*u[ijk+ii1+kk1]) * (ci0*w[ijk-ii1] + ci1*w[ijk    ] + ci2*w[ijk+ii1] + ci3*w[ijk+ii2]))
                               + cg3*((ci0*u[ijk+ii2-kk2] + ci1*u[ijk+ii2-kk1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii2+kk1]) * (ci0*w[ijk    ] + ci1*w[ijk+ii1] + ci2*w[ijk+ii2] + ci3*w[ijk+ii3])) ) * cgi*dxi;

                    wt[ijk] -= ( cg0*((ci0*v[ijk-jj1-kk2] + ci1*v[ijk-jj1-kk1] + ci2*v[ijk-jj1] + ci3*v[ijk-jj1+kk1]) * (ci0*w[ijk-jj3] + ci1*w[ijk-jj2] + ci2*w[ijk-jj1] + ci3*w[ijk    ]))
                               + cg1*((ci0*v[ijk    -kk2] + ci1*v[ijk    -kk1] + ci2*v[ijk    ] + ci3*v[ijk    +kk1]) * (ci0*w[ijk-jj2] + ci1*w[ijk-jj1] + ci2*w[ijk    ] + ci3*w[ijk+jj1]))
                               + cg2*((ci0*v[ijk+jj1-kk2] + ci1*v[ijk+jj1-kk1] + ci2*v[ijk+jj1] + ci3*v[ijk+jj1+kk1]) * (ci0*w[ijk-jj1] + ci1*w[ijk    ] + ci2*w[ijk+jj1] + ci3*w[ijk+jj2]))
                               + cg3*((ci0*v[ijk+jj2-kk2] + ci1*v[ijk+jj2-kk1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj2+kk1]) * (ci0*w[ijk    ] + ci1*w[ijk+jj1] + ci2*w[ijk+jj2] + ci3*w[ijk+jj3])) ) * cgi*dyi;

                    wt[ijk] -= ( cg0*((bi0*w[ijk-kk2] + bi1*w[ijk-kk1] + bi2*w[ijk    ] + bi3*w[ijk+kk1]) * (bi0*w[ijk-kk2] + bi1*w[ijk-kk1] + bi2*w[ijk    ] + bi3*w[ijk+kk1]))
                               + cg1*((ci0*w[ijk-kk2] + ci1*w[ijk-kk1] + ci2*w[ijk    ] + ci3*w[ijk+kk1]) * (ci0*w[ijk-kk2] + ci1*w[ijk-kk1] + ci2*w[ijk    ] + ci3*w[ijk+kk1]))
                               + cg2*((ci0*w[ijk-kk1] + ci1*w[ijk    ] + ci2*w[ijk+kk1] + ci3*w[ijk+kk2]) * (ci0*w[ijk-kk1] + ci1*w[ijk    ] + ci2*w[ijk+kk1] + ci3*w[ijk+kk2]))
                               + cg3*((ci0*w[ijk    ] + ci1*w[ijk+kk1] + ci2*w[ijk+kk2] + ci3*w[ijk+kk3]) * (ci0*w[ijk    ] + ci1*w[ijk+kk1] + ci2*w[ijk+kk2] + ci3*w[ijk+kk3])) ) * dzhi4[k];
                }
                else if (loc == 1) //==kend-1
                {
                    const int k = kend-1;
                    const int ijk = i + j*jj + k*kk;

                    wt[ijk] -= ( cg0*((ci0*u[ijk-ii1-kk2] + ci1*u[ijk-ii1-kk1] + ci2*u[ijk-ii1] + ci3*u[ijk-ii1+kk1]) * (ci0*w[ijk-ii3] + ci1*w[ijk-ii2] + ci2*w[ijk-ii1] + ci3*w[ijk    ]))
                               + cg1*((ci0*u[ijk    -kk2] + ci1*u[ijk    -kk1] + ci2*u[ijk    ] + ci3*u[ijk    +kk1]) * (ci0*w[ijk-ii2] + ci1*w[ijk-ii1] + ci2*w[ijk    ] + ci3*w[ijk+ii1]))
                               + cg2*((ci0*u[ijk+ii1-kk2] + ci1*u[ijk+ii1-kk1] + ci2*u[ijk+ii1] + ci3*u[ijk+ii1+kk1]) * (ci0*w[ijk-ii1] + ci1*w[ijk    ] + ci2*w[ijk+ii1] + ci3*w[ijk+ii2]))
                               + cg3*((ci0*u[ijk+ii2-kk2] + ci1*u[ijk+ii2-kk1] + ci2*u[ijk+ii2] + ci3*u[ijk+ii2+kk1]) * (ci0*w[ijk    ] + ci1*w[ijk+ii1] + ci2*w[ijk+ii2] + ci3*w[ijk+ii3])) ) * cgi*dxi;

                    wt[ijk] -= ( cg0*((ci0*v[ijk-jj1-kk2] + ci1*v[ijk-jj1-kk1] + ci2*v[ijk-jj1] + ci3*v[ijk-jj1+kk1]) * (ci0*w[ijk-jj3] + ci1*w[ijk-jj2] + ci2*w[ijk-jj1] + ci3*w[ijk    ]))
                               + cg1*((ci0*v[ijk    -kk2] + ci1*v[ijk    -kk1] + ci2*v[ijk    ] + ci3*v[ijk    +kk1]) * (ci0*w[ijk-jj2] + ci1*w[ijk-jj1] + ci2*w[ijk    ] + ci3*w[ijk+jj1]))
                               + cg2*((ci0*v[ijk+jj1-kk2] + ci1*v[ijk+jj1-kk1] + ci2*v[ijk+jj1] + ci3*v[ijk+jj1+kk1]) * (ci0*w[ijk-jj1] + ci1*w[ijk    ] + ci2*w[ijk+jj1] + ci3*w[ijk+jj2]))
                               + cg3*((ci0*v[ijk+jj2-kk2] + ci1*v[ijk+jj2-kk1] + ci2*v[ijk+jj2] + ci3*v[ijk+jj2+kk1]) * (ci0*w[ijk    ] + ci1*w[ijk+jj1] + ci2*w[ijk+jj2] + ci3*w[ijk+jj3])) ) * cgi*dyi;

                    wt[ijk] -= ( cg0*((ci0*w[ijk-kk3] + ci1*w[ijk-kk2] + ci2*w[ijk-kk1] + ci3*w[ijk    ]) * (ci0*w[ijk-kk3] + ci1*w[ijk-kk2] + ci2*w[ijk-kk1] + ci3*w[ijk    ]))
                               + cg1*((ci0*w[ijk-kk2] + ci1*w[ijk-kk1] + ci2*w[ijk    ] + ci3*w[ijk+kk1]) * (ci0*w[ijk-kk2] + ci1*w[ijk-kk1] + ci2*w[ijk    ] + ci3*w[ijk+kk1]))
                               + cg2*((ci0*w[ijk-kk1] + ci1*w[ijk    ] + ci2*w[ijk+kk1] + ci3*w[ijk+kk2]) * (ci0*w[ijk-kk1] + ci1*w[ijk    ] + ci2*w[ijk+kk1] + ci3*w[ijk+kk2]))
                               + cg3*((ti0*w[ijk-kk1] + ti1*w[ijk    ] + ti2*w[ijk+kk1] + ti3*w[ijk+kk2]) * (ti0*w[ijk-kk1] + ti1*w[ijk    ] + ti2*w[ijk+kk1] + ti3*w[ijk+kk2])) ) * dzhi4[k];
                }
            }
        }

    __global__ 
    void advec_s_g(double* __restrict__ st, double* __restrict__ s, 
                   double* __restrict__ u,  double* __restrict__ v, double* __restrict__ w,
                   double* __restrict__ dzi4, double dxi, double dyi, 
                   int jj, int kk,
                   int istart, int jstart, int kstart,
                   int iend,   int jend,   int kend)
    {
        const int i = blockIdx.x*blockDim.x + threadIdx.x + istart;
        const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart;
        const int k = blockIdx.z + kstart;

        const int ii1 = 1;
        const int ii2 = 2;
        const int ii3 = 3;
        const int jj1 = 1*jj;
        const int jj2 = 2*jj;
        const int jj3 = 3*jj;
        const int kk1 = 1*kk;
        const int kk2 = 2*kk;
        const int kk3 = 3*kk;

        if (i < iend && j < jend && k < kend)
        {
            const int ijk = i + j*jj + k*kk;

            if (k == kstart)
            {
                st[ijk] -= ( cg0*(u[ijk-ii1] * (ci0*s[ijk-ii3] + ci1*s[ijk-ii2] + ci2*s[ijk-ii1] + ci3*s[ijk    ]))
                           + cg1*(u[ijk    ] * (ci0*s[ijk-ii2] + ci1*s[ijk-ii1] + ci2*s[ijk    ] + ci3*s[ijk+ii1]))
                           + cg2*(u[ijk+ii1] * (ci0*s[ijk-ii1] + ci1*s[ijk    ] + ci2*s[ijk+ii1] + ci3*s[ijk+ii2]))
                           + cg3*(u[ijk+ii2] * (ci0*s[ijk    ] + ci1*s[ijk+ii1] + ci2*s[ijk+ii2] + ci3*s[ijk+ii3])) ) * cgi*dxi;

                st[ijk] -= ( cg0*(v[ijk-jj1] * (ci0*s[ijk-jj3] + ci1*s[ijk-jj2] + ci2*s[ijk-jj1] + ci3*s[ijk    ]))
                           + cg1*(v[ijk    ] * (ci0*s[ijk-jj2] + ci1*s[ijk-jj1] + ci2*s[ijk    ] + ci3*s[ijk+jj1]))
                           + cg2*(v[ijk+jj1] * (ci0*s[ijk-jj1] + ci1*s[ijk    ] + ci2*s[ijk+jj1] + ci3*s[ijk+jj2]))
                           + cg3*(v[ijk+jj2] * (ci0*s[ijk    ] + ci1*s[ijk+jj1] + ci2*s[ijk+jj2] + ci3*s[ijk+jj3])) ) * cgi*dyi;

                st[ijk] -= ( cg0*(w[ijk-kk1] * (bi0*s[ijk-kk2] + bi1*s[ijk-kk1] + bi2*s[ijk    ] + bi3*s[ijk+kk1]))
                           + cg1*(w[ijk    ] * (ci0*s[ijk-kk2] + ci1*s[ijk-kk1] + ci2*s[ijk    ] + ci3*s[ijk+kk1]))
                           + cg2*(w[ijk+kk1] * (ci0*s[ijk-kk1] + ci1*s[ijk    ] + ci2*s[ijk+kk1] + ci3*s[ijk+kk2]))
                           + cg3*(w[ijk+kk2] * (ci0*s[ijk    ] + ci1*s[ijk+kk1] + ci2*s[ijk+kk2] + ci3*s[ijk+kk3])) ) * dzi4[k];
            }
            else if (k == kend-1)
            {
                st[ijk] -= ( cg0*(u[ijk-ii1] * (ci0*s[ijk-ii3] + ci1*s[ijk-ii2] + ci2*s[ijk-ii1] + ci3*s[ijk    ]))
                           + cg1*(u[ijk    ] * (ci0*s[ijk-ii2] + ci1*s[ijk-ii1] + ci2*s[ijk    ] + ci3*s[ijk+ii1]))
                           + cg2*(u[ijk+ii1] * (ci0*s[ijk-ii1] + ci1*s[ijk    ] + ci2*s[ijk+ii1] + ci3*s[ijk+ii2]))
                           + cg3*(u[ijk+ii2] * (ci0*s[ijk    ] + ci1*s[ijk+ii1] + ci2*s[ijk+ii2] + ci3*s[ijk+ii3])) ) * cgi*dxi;

                st[ijk] -= ( cg0*(v[ijk-jj1] * (ci0*s[ijk-jj3] + ci1*s[ijk-jj2] + ci2*s[ijk-jj1] + ci3*s[ijk    ]))
                           + cg1*(v[ijk    ] * (ci0*s[ijk-jj2] + ci1*s[ijk-jj1] + ci2*s[ijk    ] + ci3*s[ijk+jj1]))
                           + cg2*(v[ijk+jj1] * (ci0*s[ijk-jj1] + ci1*s[ijk    ] + ci2*s[ijk+jj1] + ci3*s[ijk+jj2]))
                           + cg3*(v[ijk+jj2] * (ci0*s[ijk    ] + ci1*s[ijk+jj1] + ci2*s[ijk+jj2] + ci3*s[ijk+jj3])) ) * cgi*dyi;

                st[ijk] -= ( cg0*(w[ijk-kk1] * (ci0*s[ijk-kk3] + ci1*s[ijk-kk2] + ci2*s[ijk-kk1] + ci3*s[ijk    ]))
                           + cg1*(w[ijk    ] * (ci0*s[ijk-kk2] + ci1*s[ijk-kk1] + ci2*s[ijk    ] + ci3*s[ijk+kk1]))
                           + cg2*(w[ijk+kk1] * (ci0*s[ijk-kk1] + ci1*s[ijk    ] + ci2*s[ijk+kk1] + ci3*s[ijk+kk2]))
                           + cg3*(w[ijk+kk2] * (ti0*s[ijk-kk1] + ti1*s[ijk    ] + ti2*s[ijk+kk1] + ti3*s[ijk+kk2])) ) * dzi4[k];
            }
            else
            {
                st[ijk] -= ( cg0*(u[ijk-ii1] * (ci0*s[ijk-ii3] + ci1*s[ijk-ii2] + ci2*s[ijk-ii1] + ci3*s[ijk    ]))
                           + cg1*(u[ijk    ] * (ci0*s[ijk-ii2] + ci1*s[ijk-ii1] + ci2*s[ijk    ] + ci3*s[ijk+ii1]))
                           + cg2*(u[ijk+ii1] * (ci0*s[ijk-ii1] + ci1*s[ijk    ] + ci2*s[ijk+ii1] + ci3*s[ijk+ii2]))
                           + cg3*(u[ijk+ii2] * (ci0*s[ijk    ] + ci1*s[ijk+ii1] + ci2*s[ijk+ii2] + ci3*s[ijk+ii3])) ) * cgi*dxi;

                st[ijk] -= ( cg0*(v[ijk-jj1] * (ci0*s[ijk-jj3] + ci1*s[ijk-jj2] + ci2*s[ijk-jj1] + ci3*s[ijk    ]))
                           + cg1*(v[ijk    ] * (ci0*s[ijk-jj2] + ci1*s[ijk-jj1] + ci2*s[ijk    ] + ci3*s[ijk+jj1]))
                           + cg2*(v[ijk+jj1] * (ci0*s[ijk-jj1] + ci1*s[ijk    ] + ci2*s[ijk+jj1] + ci3*s[ijk+jj2]))
                           + cg3*(v[ijk+jj2] * (ci0*s[ijk    ] + ci1*s[ijk+jj1] + ci2*s[ijk+jj2] + ci3*s[ijk+jj3])) ) * cgi*dyi;

                st[ijk] -= ( cg0*(w[ijk-kk1] * (ci0*s[ijk-kk3] + ci1*s[ijk-kk2] + ci2*s[ijk-kk1] + ci3*s[ijk    ]))
                           + cg1*(w[ijk    ] * (ci0*s[ijk-kk2] + ci1*s[ijk-kk1] + ci2*s[ijk    ] + ci3*s[ijk+kk1]))
                           + cg2*(w[ijk+kk1] * (ci0*s[ijk-kk1] + ci1*s[ijk    ] + ci2*s[ijk+kk1] + ci3*s[ijk+kk2]))
                           + cg3*(w[ijk+kk2] * (ci0*s[ijk    ] + ci1*s[ijk+kk1] + ci2*s[ijk+kk2] + ci3*s[ijk+kk3])) ) * dzi4[k];
            }
        }
    }

    __global__ 
    void calc_cfl_g(double* const __restrict__ tmp1,
                    const double* const __restrict__ u, const double* const __restrict__ v, const double* const __restrict__ w, 
                    const double* const __restrict__ dzi, const double dxi, const double dyi,
                    const int jj, const int kk,
                    const int istart, const int jstart, const int kstart,
                    const int iend,   const int jend,   const int kend)
    {
        const int i = blockIdx.x*blockDim.x + threadIdx.x + istart; 
        const int j = blockIdx.y*blockDim.y + threadIdx.y + jstart; 
        const int k = blockIdx.z + kstart; 

        const int ii1 = 1;
        const int ii2 = 2;
        const int jj1 = 1*jj;
        const int jj2 = 2*jj;
        const int kk1 = 1*kk;
        const int kk2 = 2*kk;

        const int ijk = i + j*jj + k*kk;

        if (i < iend && j < jend && k < kend)
            tmp1[ijk] = std::abs(ci0*u[ijk-ii1] + ci1*u[ijk] + ci2*u[ijk+ii1] + ci3*u[ijk+ii2])*dxi + 
                        std::abs(ci0*v[ijk-jj1] + ci1*v[ijk] + ci2*v[ijk+jj1] + ci3*v[ijk+jj2])*dyi + 
                        std::abs(ci0*w[ijk-kk1] + ci1*w[ijk] + ci2*w[ijk+kk1] + ci3*w[ijk+kk2])*dzi[k];
    }
}

#ifdef USECUDA
unsigned long Advec_4::get_time_limit(unsigned long idt, double dt)
{
    // Calculate cfl and prevent zero divisons.
    double cfl = get_cfl(dt);
    cfl = std::max(cflmin, cfl);
    const unsigned long idtlim = idt * cflmax / cfl;
    return idtlim;
}

double Advec_4::get_cfl(const double dt)
{
    const int blocki = grid->ithread_block;
    const int blockj = grid->jthread_block;
    const int gridi  = grid->icells/blocki + (grid->icells%blocki > 0);
    const int gridj  = grid->jcells/blockj + (grid->jcells%blockj > 0);

    dim3 gridGPU (gridi, gridj, grid->kcells);
    dim3 blockGPU(blocki, blockj, 1);

    const double dxi = 1./grid->dx;
    const double dyi = 1./grid->dy;

    const int offs = grid->memoffset;

    calc_cfl_g<<<gridGPU, blockGPU>>>(
        &fields->atmp["tmp1"]->data_g[offs],
        &fields->u->data_g[offs], &fields->v->data_g[offs], &fields->w->data_g[offs],
        grid->dzi_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    double cfl = grid->get_max_g(&fields->atmp["tmp1"]->data_g[offs], fields->atmp["tmp2"]->data_g); 
    grid->get_max(&cfl); 
    cfl = cfl*dt;

    return cfl;
}

void Advec_4::exec()
{
    const int blocki = grid->ithread_block;
    const int blockj = grid->jthread_block;
    const int gridi  = grid->imax/blocki + (grid->imax%blocki > 0);
    const int gridj  = grid->jmax/blockj + (grid->jmax%blockj > 0);

    dim3 gridGPU (gridi, gridj, grid->kmax);
    dim3 blockGPU(blocki, blockj, 1);

    dim3 gridGPU2D (gridi, gridj, 1);
    dim3 blockGPU2D(blocki, blockj, 1);

    const double dxi = 1./grid->dx;
    const double dyi = 1./grid->dy;

    const int offs = grid->memoffset;

    // Top and bottom boundary:
    advec_u_boundary_g<0><<<gridGPU2D, blockGPU2D>>>(
        &fields->ut->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    advec_u_boundary_g<1><<<gridGPU2D, blockGPU2D>>>(
        &fields->ut->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    // Interior:
    advec_u_g<<<gridGPU, blockGPU>>>(
        &fields->ut->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    // Top and bottom boundary:
    advec_v_boundary_g<0><<<gridGPU2D, blockGPU2D>>>(
        &fields->vt->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    advec_v_boundary_g<1><<<gridGPU2D, blockGPU2D>>>(
        &fields->vt->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    // Interior
    advec_v_g<<<gridGPU, blockGPU>>>(
        &fields->vt->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    // Top and bottom boundary:
    advec_w_boundary_g<0><<<gridGPU2D, blockGPU2D>>>(
        &fields->wt->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzhi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    advec_w_boundary_g<1><<<gridGPU2D, blockGPU2D>>>(
        &fields->wt->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzhi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    // Interior:
    advec_w_g<<<gridGPU, blockGPU>>>(
        &fields->wt->data_g[offs], &fields->u->data_g[offs], &fields->v->data_g[offs], 
        &fields->w->data_g[offs], grid->dzhi4_g, dxi, dyi,
        grid->icellsp, grid->ijcellsp,
        grid->istart,  grid->jstart, grid->kstart,
        grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 

    for(FieldMap::const_iterator it = fields->st.begin(); it!=fields->st.end(); it++)
        advec_s_g<<<gridGPU, blockGPU>>>(
            &it->second->data_g[offs], &fields->sp[it->first]->data_g[offs], 
            &fields->u->data_g[offs], &fields->v->data_g[offs], &fields->w->data_g[offs], 
            grid->dzi4_g, dxi, dyi,
            grid->icellsp, grid->ijcellsp,
            grid->istart,  grid->jstart, grid->kstart,
            grid->iend,    grid->jend,   grid->kend);
    cuda_check_error(); 
}
#endif
