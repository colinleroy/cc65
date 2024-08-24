;
; Apple2's callmain.s is empty to avoid linking the general
; runtime/callmain.s.
;
; On apple2, callmain is in crt0.s for a more logical memory
; layout, with _exit() in the CODE segment rather than in the
; STARTUP segment.
;
