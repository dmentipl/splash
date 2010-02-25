!-----------------------------------------------------------------
!
!  This file is (or was) part of SPLASH, a visualisation tool 
!  for Smoothed Particle Hydrodynamics written by Daniel Price:
!
!  http://users.monash.edu.au/~dprice/splash
!
!  SPLASH comes with ABSOLUTELY NO WARRANTY.
!  This is free software; and you are welcome to redistribute
!  it under the terms of the GNU General Public License
!  (see LICENSE file for details) and the provision that
!  this notice remains intact. If you modify this file, please
!  note section 2a) of the GPLv2 states that:
!
!  a) You must cause the modified files to carry prominent notices
!     stating that you changed the files and the date of any change.
!
!  Copyright (C) 2005-2009 Daniel Price. All rights reserved.
!  Contact: daniel.price@sci.monash.edu.au
!
!-----------------------------------------------------------------

!------------------------------------------------------------------------
!  Module containing "interface" routines between the calculated
!  pixel arrays and the PGPLOT routines which do the actual rendering
!------------------------------------------------------------------------
module render
 use colourbar, only:plotcolourbar
 implicit none
 public :: render_pix, render_vec
 private

contains

!------------------------------------------------------------------------
!  this subroutine takes a 2D grid of data and renders it using pgplot
!  rendering is either greyscale (icolours = 1) or colour (icolours>1)
!  also plots nc contours between datmin and datmax.
!------------------------------------------------------------------------
 
subroutine render_pix(datpix,datmin,datmax,label,npixx,npixy, &
                  xmin,ymin,dx,icolours,iplotcont,iColourBarStyle,nc,log, &
                  ilabelcont,contmin,contmax,blank)
 use plotutils, only:formatreal
 use plotlib,   only:plot_imag,plot_conb,plot_cons,plot_qch,plot_sch,plot_qch,plot_sch,plot_conl
 implicit none
 integer, intent(in) :: npixx,npixy,nc,icolours
 real, intent(in) :: xmin,ymin,datmin,datmax,dx
 real, dimension(npixx,npixy), intent(in) :: datpix
 logical, intent(in) :: iplotcont,log,ilabelcont
 integer, intent(in) :: iColourBarStyle
 character(len=*), intent(in) :: label
 real, intent(in), optional :: contmin,contmax,blank
 
 integer :: i
 real :: trans(6),levels(nc),dcont,charheight,cmin,cmax
 character(len=12) :: string
! 
!--set up grid for rendering 
!
 trans(1) = xmin - 0.5*dx                ! this is for the pgimag call
 trans(2) = dx                        ! see help for pgimag/pggray/pgcont
 trans(3) = 0.0
 trans(4) = ymin - 0.5*dx
 trans(5) = 0.0
 trans(6) = dx

 print*,'rendering...',npixx,'x',npixy,'=',size(datpix),' pixels'

! if (abs(icolours).eq.1) then        ! greyscale
!    if (iPlotColourBar) call colourbar(icolours,datmin,datmax,trim(label),log)
!    call pggray(datpix,npixx,npixy,1,npixx,1,npixy,datmin,datmax,trans)

 if (abs(icolours).gt.0) then        ! colour
    if (iColourBarStyle.gt.0) call plotcolourbar(iColourBarstyle,icolours,datmin,datmax,trim(label),log,0.)
!    call pgwedg('ri',2.0,4.0,datmin,datmax,' ')
    call plot_imag(datpix,npixx,npixy,1,npixx,1,npixy,datmin,datmax,trans)
!    call pghi2d(datpix,npixx,npixx,1,npixx,1,npixx,1,0.1,.true.,y) 
 endif
!
!--contours
!
 if (iplotcont) then
    if (present(contmin)) then
       cmin = contmin
    else
       cmin = datmin
    endif
    if (present(contmax)) then
       cmax = contmax
    else
       cmax = datmax
    endif
!
!--set contour levels
! 
    if (nc.le.0) then
       print*,'ERROR: cannot plot contours with ',nc,' levels'
       return
    elseif (nc.eq.1) then
       levels(1) = cmin
       dcont = 0.
    else
       dcont = (cmax-cmin)/real(nc-1)   ! even contour levels
       do i=1,nc
          levels(i) = cmin + real(i-1)*dcont
       enddo
    endif
!
!--plot contours (use pgcont if pgcons causes trouble)
!  with blanking if blank is input
!
    if (present(blank)) then
       print 10,nc,' contours (with blanking)',levels(1),levels(nc),dcont
       print 20,levels(1:nc)
       !print*,' blanking = ',blank,'min,max = ',datmin,datmax
       call plot_conb(datpix,npixx,npixy,1,npixx,1,npixy,levels,nc,trans,blank)
    else
       print 10,nc,' contours',levels(1),levels(nc),dcont
       print 20,levels(1:nc)
       call plot_cons(datpix,npixx,npixy,1,npixx,1,npixy,levels,nc,trans)
    endif
10  format(1x,'plotting ',i4,a,' between ',1pe10.2,' and ',1pe10.2,', every ',1pe10.2,':')
20  format(10(6(1x,1pe9.2),/))
!
!--labelling of contour levels
!
    if (ilabelcont) then
       call plot_qch(charheight)       ! query character height
       call plot_sch(0.75*charheight)   ! shrink character height

       do i=1,nc
          call formatreal(levels(i),string)
          call plot_conl(datpix,npixx,npixy,1,npixx,1,npixy,levels(i),trans,trim(string),npixx/2,30)
       enddo
       call plot_sch(charheight) ! restore character height
    endif
!
!--this line prints the label inside the contour plot
!  (now obsolete-- this functionality can be achieved using plot titles)
!    call pgmtxt('T',-2.0,0.05,0.0,trim(label))

 endif
 
 return
 
end subroutine render_pix

!--------------------------------------------------------------------------
!  this subroutine takes a 2D grid of vector data (ie. x and y components)
!  and plots an arrow map of it
!--------------------------------------------------------------------------
 
subroutine render_vec(vecpixx,vecpixy,vecmax,npixx,npixy,        &
                  xmin,ymin,dx,label,unitslabel) 
 use legends,          only:legend_vec
 use settings_vecplot, only:iVecplotLegend,hposlegendvec,vposlegendvec,iplotarrowheads,&
                            iallarrowssamelength
 use plotlib,          only:plot_sah,plot_qch,plot_sch,plot_vect
 implicit none
 integer, intent(in) :: npixx,npixy
 real, intent(in) :: xmin,ymin,dx
 real, intent(inout) :: vecmax
 real, dimension(npixx,npixy), intent(in) :: vecpixx,vecpixy
 real, dimension(npixx,npixy) :: dvmag
 character(len=*), intent(in) :: label,unitslabel
 real :: trans(6),scale
 real :: charheight
 
!set up grid for rendering 

 trans(1) = xmin - 0.5*dx                ! this is for the pgimag call
 trans(2) = dx                        ! see help for pgimag/pggray/pgcont
 trans(3) = 0.0
 trans(4) = ymin - 0.5*dx
 trans(5) = 0.0
 trans(6) = dx

 print*,'vector plot..',npixx,'x',npixy,'=',size(vecpixx),' pixels'
 !!print*,'max(x component) = ',maxval(vecpixx),'max(y component) = ',maxval(vecpixy)

 if (iplotarrowheads) then
    call plot_sah(2,45.0,0.7)   ! arrow style
 else
    call plot_sah(2,0.0,1.0)
 endif
 call plot_qch(charheight)
 call plot_sch(0.3)          ! size of arrow head
 
 if (iallarrowssamelength) then
    !!if (vecmax.le.0.0) vecmax = 1.0 ! adaptive limits
    scale=0.9*dx !!/vecmax
    print*,trim(label),' showing direction only: max = ',vecmax

    where (abs(vecpixx).gt.tiny(vecpixx) .and. abs(vecpixy).gt.tiny(vecpixy)) 
       dvmag(:,:) = 1./sqrt(vecpixx**2 + vecpixy**2)
    elsewhere
       dvmag(:,:) = 0.
    end where
    
    call plot_vect(vecpixx(:,:)*dvmag(:,:),vecpixy(:,:)*dvmag(:,:),npixx,npixy, &
         1,npixx,1,npixy,scale,0,trans,0.0)
 else
    if (vecmax.le.0.0) then  ! adaptive limits
       scale = 0.0
       vecmax = max(maxval(vecpixx(:,:)),maxval(vecpixy(:,:)))
       if (vecmax.gt.0.) scale = dx/vecmax
    else
       scale=dx/vecmax
    endif
    print*,trim(label),' max = ',vecmax

    call plot_vect(vecpixx(:,:),vecpixy(:,:),npixx,npixy, &
         1,npixx,1,npixy,scale,0,trans,0.0)

    if (iVecplotLegend) then
       call legend_vec(label,unitslabel,vecmax,dx,hposlegendvec,vposlegendvec,charheight)
    endif
 endif
 
 call plot_sch(charheight)
 
 return
 
end subroutine render_vec

end module render
