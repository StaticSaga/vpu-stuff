.text
.globl _start
.align 2

_start:
  mov r5, r0
  mov r6, #32

  v16mov H16(6,0), #0

  ; 0: cr,  1: ci,  2: zr,  3: zi,  4: temp{zr*zi},  5: temp2{zr^2+zi^2},  6: iterations
  mov r1, #0 ; loop ctr

  v16ld H16(0++,0),(r5+=r6) REP2 ; load cr and ci
  v16mov H16(2++,0), H16(0++,0) REP2 ; zr=cr, zi=ci

  v16sub -, H16(0, 0), #1 SETF ; set neg flag, UGLY HACK

loopstart:
  v16asr H16(2++,0), H16(2++,0), #6 REP2 
  vmull.ss H16(4,0), H16(2,0), H16(3,0) ; temp = zr*zi
  vmull.ss H16(2++,0), H16(2++,0), H16(2++,0) REP2 ; zr^2, zi^2
  v16add H16(5,0), H16(2,0), H16(3,0) ; temp2 = zr^2 + zi^2
  v16sub -, H16(5,0), #16384 IFN SETF ; negative = less than 4.0
  v16add H16(6,0), H16(6,0), #1 IFN MAX r0 ; if (max != itercount) all points have escaped

  v16sub H16(2,0), H16(2,0), H16(3,0) ; zr = zr^2 - zi^2
  v16add H16(3,0), H16(4,0), H16(4,0) ; zi = 2*temp
  v16add H16(2++,0), H16(2++,0), H16(0++,0) REP2 ; zr += cr, zi += ci
  
  bgt r1, r0, loopend ; if all points are already out, quit early 
  add r1, r1, #1
  bne r1, #32, loopstart ; completed all iterations (at least one point was still inside) 

loopend:
  mov r0, r1 ; return iteration count
  v16st H16(6++,0), (r5+=r6) REP2 ; store zr and zi
  
  rts


