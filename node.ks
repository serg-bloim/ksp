until 0 {
	wait until NOT HASNODE.
	LOCAL m_time IS TIME:SECONDS + ETA:APOAPSIS.
	LOCAL vel_as IS VELOCITYAT(SHIP, m_time):ORBIT:MAG.
	LOCAL vel_ps IS VELOCITYAT(SHIP, TIME:SECONDS + ETA:PERIAPSIS):ORBIT:MAG.
	LOCAL obt_as IS ORBITAT(SHIP, m_time).
	LOCAL sma_as IS obt_as:BODY:RADIUS + obt_as:APOAPSIS.
	LOCAL new_obt_v IS SQRT(obt_as:BODY:MU/sma_as).
	LOCAL dv IS new_obt_v - vel_as.
	PRINT "Velocity @ Apop " + vel_ps.
	PRINT "Velocity @ Apop " + vel_as.
	PRINT "Velocity @ Circular Orbit " + new_obt_v.
	PRINT "DV " + dv.
	PRINT "Semimajor axis @ Apop is " + sma_as.
	SET X TO NODE(m_time, 0, 0, dv).
	ADD X.
}