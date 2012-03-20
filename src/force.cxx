#include <cstdio>
#include "grid.h"
#include "fields.h"
#include "force.h"

cforce::cforce(cgrid *gridin, cfields *fieldsin)
{
  std::printf("Creating instance of object force\n");
  grid   = gridin;
  fields = fieldsin;
}

cforce::~cforce()
{
  std::printf("Destroying instance of object force\n");
}

int cforce::exec(double dt)
{
  flux((*fields->ut).data, (*fields->u).data, grid->dz, dt);

  return 0;
}

int cforce::flux(double * __restrict__ ut, double * __restrict__ u, double * __restrict__ dz, double dt)
{
  int ijk,ii,jj,kk;

  ii = 1;
  jj = grid->icells;
  kk = grid->icells*grid->jcells;
  
  double uavg, utavg;

  uavg  = 0.;
  utavg = 0.;

  for(int k=grid->kstart; k<grid->kend; k++)
    for(int j=grid->jstart; j<grid->jend; j++)
      for(int i=grid->istart; i<grid->iend; i++)
      {
        ijk = i + j*jj + k*kk;
        uavg  = uavg  + u [ijk]*dz[k];
        utavg = utavg + ut[ijk]*dz[k];
      }

  uavg  = uavg  / (grid->itot*grid->jtot*grid->zsize);
  utavg = utavg / (grid->itot*grid->jtot*grid->zsize);

  const double uflux = 0.0282;

  double fbody; 
  fbody = (uflux - uavg) / dt - utavg;

  for(int n=0; n<grid->ncells; n++)
    ut[n] += fbody;

  return 0;
}

/*
real    :: umavg, utavg, Umean, Pbody
integer :: i, j, k

umavg = 0.
utavg = 0.

do j = 1,jmax
  do i = 1,imax
    do k = 1,kmax
      umavg = umavg + um(k,i,j)*dz(k)
      utavg = utavg + ut(k,i,j)*dz(k)
    end do
  end do
end do

umavg = umavg / (imax*jmax*zsize)
utavg = utavg / (imax*jmax*zsize)

!CvH for now, set Umean to 0.115 m/s
Umean = 0.115

Pbody = (Umean - umavg) / rk3coef - utavg

ut(1:kmax,1:imax,1:jmax) = ut(1:kmax,1:imax,1:jmax) + Pbody
*/