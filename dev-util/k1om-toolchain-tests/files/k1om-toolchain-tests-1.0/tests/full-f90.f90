! libgfortran + real(16) via libquadmath: formatted I/O, intrinsics, arrays.
program f90
  implicit none
  integer, parameter :: qp = selected_real_kind(33)
  real(qp) :: x, s
  real(8) :: a(1000)
  integer :: i
  character(len=60) :: buf
  x = sqrt(2.0_qp)
  write (*, '(A,ES42.33E2)') 'sqrt2 ', x
  write (*, '(A,ES42.33E2)') 'e     ', exp(1.0_qp)
  s = 0
  do i = 1, 100
    s = s + 1.0_qp / real(i, qp)**2
  end do
  write (*, '(A,ES42.33E2)') 'zeta2 ', s
  a = [(real(i, 8), i = 1, 1000)]
  write (*, '(A,F12.1,I8)') 'sum   ', sum(a), maxloc(a, 1)
  write (buf, '(3I5)') 1, 22, 333
  read (buf, *) i
  write (*, '(A,A,I4)') 'io    ', trim(adjustl(buf)), i
end program f90
