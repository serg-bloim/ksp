RUNONCEPATH("0://util/randevous.ks").
RUNONCEPATH("0://app/mun_lifter.ks").

CLEARVECDRAWS().
// mun_lifter(FALSE).
do_randevous(TARGET).

local T_x is NEXTNODE:TIME + NEXTNODE:ORBIT:PERIOD/2.

local spos is POSITIONAT(SHIP, T_x).
local tpos is POSITIONAT(TARGET, T_x).
print "Dist at approach is: " + (tpos - spos):MAG.
show_vect(spos).
show_vect(tpos).