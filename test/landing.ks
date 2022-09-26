CLEARSCREEN.
print "Prepare".
local angle_func_a is 2.55.
local angle_func_b is 1.
local angle_func_c is 11600.
local angle_func_d is 14700.
local angle_func_h is 15.
print "angle_func_a = " + angle_func_a.
print "angle_func_b = " + angle_func_b.
print "angle_func_c = " + angle_func_c.
print "angle_func_d = " + angle_func_d.
print "angle_func_h = " + angle_func_h.
set throt to lexicon().
throt:add(0, 1).
throt:add(5000, 0.6).
throt:add(10000, 0.8).
throt:add(30000, 1).
wait until ship:loaded.
//wait 20.
SAS OFF.
print "Start".
LOCK STEERING TO Up + R(0,0,0).
SET SHIP:CONTROL:PILOTMAINTHROTTLE to 1.
STAGE.

ON FLOOR(ALTITUDE/1000) {
	set angle to angle_func_a * (arctan(angle_func_b * (ALTITUDE - angle_func_d) / angle_func_c)/CONSTANT:PI + angle_func_h).
	if angle < 0 {
		set angle to 0.
	}
	if angle > 90 {
		set angle to 90.
	}
	print "ALTITUDE: " + ALTITUDE.
	print "ANGLE: " + ROUND(angle,1) + "º".
	LOCK STEERING TO Up + R(angle,0,0).
	return true.
}
for alt in throt:keys {
	local a is alt.
	print "when ALTITUDE > " + alt.
	when ALTITUDE > a then{
		print "Throttle control".
		print "ALTITUDE: " + ALTITUDE.
		print "THROTTLE: " + throt[a].
		SET SHIP:CONTROL:PILOTMAINTHROTTLE to throt[a].
	}
}
wait 1000.
SAS ON.
print "End".