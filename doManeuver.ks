SET ListNodes TO ALLNODES.
set BurnTime to maneuverBurnTime(ListNodes[0]).
LOCK STEERING TO ListNodes[0]:BURNVECTOR.
local startTime is calculateStartTime(ListNodes[0]).
warpto(startTime - 120).
wait until time:seconds > startTime.
lock throttle to 1.
wait until(isManeuverComplete(ListNodes[0])).
lock throttle to 0.


function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
}

function maneuverBurnTime {
  parameter mnv.
  local dV is mnv:deltaV:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
    }
  }
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return true.
  }
  return false.
}

