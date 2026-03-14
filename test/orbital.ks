RUNONCEPATH("0://util/dbg.ks").
RUNONCEPATH("0://util/dir.ks").
RUNONCEPATH("0://util/orb.ks").
RUNONCEPATH("0://app/body_lift.ks").
RUNONCEPATH("0://app/randevous.ks").

// local app to create_app_body_lift().
// set app:cfg:ALT to 30000.
// set app:cfg:AUTOSTART to FALSE.
// app:run().


local app to create_app_randevous().
set app:cfg:target to TARGET.
set app:cfg:AUTOSTART to FALSE.
app:run().