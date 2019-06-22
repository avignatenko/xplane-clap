dataref("AP", "sim/cockpit/autopilot/autopilot_mode", "readonly")

CL_AP_Pitch = create_dataref_table("ai/ap/pitch_active", "Int")
CL_AP_Roll = create_dataref_table("ai/ap/roll_active", "Int")


dataref("yoke_pitch", "sim/joystick/yoke_pitch_ratio", "writable")
dataref("yoke_roll", "sim/joystick/yoke_roll_ratio", "writable")
dataref("yoke_yaw",  "sim/joystick/yoke_heading_ratio", "writable")

dataref("yoke_pitch_total", "sim/cockpit2/controls/total_pitch_ratio")
dataref("yoke_roll_total", "sim/cockpit2/controls/total_roll_ratio")
dataref("yoke_yaw_total",  "sim/cockpit2/controls/total_heading_ratio")

dataref("trim_sim",  "sim/flightmodel2/controls/elevator_trim", "writable")
dataref("trim_max", "sim/aircraft/controls/acf_max_trim_elev")
dataref("trim_min", "sim/aircraft/controls/acf_min_trim_elev")


-- servo
dataref("servo_roll", "sim/joystick/servo_roll_ratio")
dataref("servo_pitch", "sim/joystick/servo_pitch_ratio")
dataref("servo_yaw", "sim/joystick/servo_heading_ratio")

dataref("aileron_max_def_down", "sim/aircraft/controls/acf_ail1_dn")
dataref("aileron_max_def_up", "sim/aircraft/controls/acf_ail1_up")

dataref("elevator_max_def_down", "sim/aircraft/controls/acf_elev_dn")
dataref("elevator_max_def_up", "sim/aircraft/controls/acf_elev_up")

dataref("rudder_max_def_lr", "sim/aircraft/controls/acf_rudd_lr")
dataref("rudder_max_def_rr", "sim/aircraft/controls/acf_rudd_rr")


dataref("ail_L", "sim/flightmodel2/wing/aileron1_deg", "writable", 4)
dataref("ail_R", "sim/flightmodel2/wing/aileron1_deg", "writable", 5)

dataref("elev_L", "sim/flightmodel2/wing/elevator1_deg", "writable", 8)
dataref("elev_R", "sim/flightmodel2/wing/elevator1_deg", "writable", 9)

dataref("rudder", "sim/flightmodel2/wing/rudder1_deg", "writable", 10)
 
flaps = dataref_table ("sim/flightmodel2/wing/flap1_deg")
dataref("flaps_deploy_ratio", "sim/flightmodel2/controls/flap_handle_deploy_ratio")

-- 

function clamp(value, min, max)
  if value > max then return max end
  if value < min then return min end
  return value
end 

local currentAP = AP
local pilot_roll = 0
local pilot_pitch = 0

local have_control = false

function take_control(enable)

  print ("CL script " .. (enabled and "enabled" or "disabled"))
  
  have_control = enable  
  set("sim/operation/override/override_control_surfaces", have_control and 1 or 0)

end

function update_controls()

if not have_control then return end 

-- 1) set yoke_roll and yoke_pitch

if currentAP ~= AP then
  if AP ~= 2 then
      logMsg("CL Support: A/P disengaged")
	  
	  -- trim is ignored anyway, so set it zero just in case
	  trim_sim = 0
	  
	  -- inform CL about AP off
	  CL_AP_Pitch[0] = 0
	  CL_AP_Roll[0] = 0
  else
  
      logMsg("CL Support: A/P engaged")
	  
	  -- inform CL about AP on
	  CL_AP_Pitch[0] = 1
	  CL_AP_Roll[0] = 1	  
  end
  
  currentAP = AP
  
end

-- A/P disengaged?
if AP ~= 2 then

  -- save last joy positions to avoid jump when AP is on.
  pilot_roll = yoke_roll
  pilot_pitch = yoke_pitch
 
  -- we don't set yoke_pitch / yoke_roll here because they will be set automatically

else  -- A/P engaged

  local trim_2_elev = trim_sim
  if trim_sim > 0 then trim_2_elev = trim_2_elev * trim_max
  else trim_2_elev = trim_2_elev * trim_min
  end
  
  -- send servo and trim to yoke position instead of elevator position (used by default)
  yoke_pitch = clamp(pilot_pitch + servo_pitch  + trim_2_elev, -1, 1)
  -- a/p is not using roll trim, so don't use it here (fixme, might be add?)
  yoke_roll = clamp(pilot_roll + servo_roll, -1, 1)
   
end


-- 2) set surfaces angles from yoke_pitch and yoke_roll

-- AILERONS

if	yoke_roll_total > 0
	then	ail_L =   aileron_max_def_down * yoke_roll_total
		    ail_R = - aileron_max_def_up * yoke_roll_total
	else	ail_L =   aileron_max_def_up * yoke_roll_total
		    ail_R = - aileron_max_def_down * yoke_roll_total
end

-- ELEVATOR
 
if	yoke_pitch_total > 0
	then	elev_L = - elevator_max_def_up * yoke_pitch_total
		    elev_R =  - elevator_max_def_up * yoke_pitch_total 
	else	elev_L = - elevator_max_def_down * yoke_pitch_total
		    elev_R = - elevator_max_def_down * yoke_pitch_total
end

-- RUDDER

-- fixme: take left/right into account
if yoke_yaw_total > 0 then
  rudder = rudder_max_def_rr * yoke_yaw_total
else
  rudder = rudder_max_def_lr * yoke_yaw_total  
end

-- FLAPS

-- fixme: get extension angle from acf datarefs
-- fixme: get number of flaps from acf datarefs
for i=0,3 do 
  flaps[i] = flaps_deploy_ratio * 30.0
end

end


-- make a switchable menu entry , default is on 
add_macro(" CL Yoke" , "take_control(true)" , "take_control(false)" , "activate")


do_every_frame ("update_controls()")