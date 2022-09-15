RUNONCEPATH("/util/utils.ks").
CLEARSCREEN.
print("ship:maxthrust: " + ship:maxthrust).
local total_fuel_consumption is 0.
local total_thrust is 0.
local THRUSTLIMIT is 0.
LIST ENGINES in eng.
for e in eng{
    if e:IGNITION{
        set total_fuel_consumption to total_fuel_consumption + e:MAXMASSFLOW*e:THRUSTLIMIT/100.
        set THRUSTLIMIT to e:THRUSTLIMIT.
    }
}

print("total_fuel_consumption: " + total_fuel_consumption).
print("THRUSTLIMIT: " + THRUSTLIMIT).
wait_until_esc().