dataref("AP", "sim/cockpit/autopilot/autopilot_mode", "readonly")

--debug_params = create_dataref_table("ai/ap/debug", "FloatArray")

dataref("paused", "sim/time/paused")

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

function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

function clamp(value, min, max)
  if value > max then return max end
  if value < min then return min end
  return value
end 

--

local currentAP = AP
local pilot_roll = 0
local pilot_pitch = 0

local have_control = false

local last_pilot_controls_shift_run = -1
local pilot_controls_shift_speed = 0.01 -- per/sec, fixme: read from A/P servo speed

--

function take_control(enable)

  print ("CL script " .. (enabled and "enabled" or "disabled"))
  
  have_control = enable  
  set("sim/operation/override/override_control_surfaces", have_control and 1 or 0)

end

function shift_pilot_controls_to_zero()
    
  local now = os.clock();   

  if last_pilot_controls_shift_run < 0 then last_pilot_controls_shift_run = now end
  
  local delta = (now - last_pilot_controls_shift_run) * pilot_controls_shift_speed
  last_pilot_controls_shift_run = now

  if math.abs(pilot_pitch) > 0.001 then   
    local pitch_sign = sign(pilot_pitch)
    pilot_pitch = pilot_pitch - pitch_sign * delta
    if sign(pilot_pitch) ~= pitch_sign then pilot_pitch = 0.0 end
  end
  
  if math.abs(pilot_roll) > 0.001 then
    local roll_sign = sign(pilot_roll)
    pilot_roll = pilot_roll - roll_sign * delta
    if sign(pilot_roll) ~= roll_sign then pilot_roll = 0.0 end
  end
    
end

function trim2elev(trim)
  local mult = (trim > 0 and trim_max or trim_min)
  return clamp(trim * mult, -1, 1)
end

function elev2trim(elev)
  local mult = (elev > 0 and (1 / trim_max) or (1 / trim_min))
  return clamp(elev * mult, -1, 1)
end

function update_controls()

if paused == 1 then return end
if not have_control then return end 

-- 1) set yoke_roll and yoke_pitch

if currentAP ~= AP then
  if AP ~= 2 then
      logMsg("CL Support: A/P disengaged")
	  
      last_pilot_controls_shift_run = -1

	  -- trim is ignored anyway, so set it zero just in case
	  trim_sim = 0
	  
  else
  
      logMsg("CL Support: A/P engaged")
      
	  trim_sim = elev2trim(pilot_pitch)
	  pilot_pitch = clamp(pilot_pitch - trim2elev(trim_sim), -1, 1)
	  	
  end
    
end

-- A/P disengaged?
if AP ~= 2 then

  -- save last joy positions to avoid jump when AP is on.
  pilot_roll = yoke_roll
  pilot_pitch = yoke_pitch
 
  -- we don't set yoke_pitch / yoke_roll here because they will be set automatically

else  -- A/P engaged

  -- experimental!
  shift_pilot_controls_to_zero()
  
  -- send servo and trim to yoke position instead of elevator position (used by default)
  yoke_pitch = clamp(pilot_pitch + servo_pitch  + trim2elev(trim_sim), -1, 1)
  -- a/p is not using roll trim, so don't use it here (fixme, might be add?)
  yoke_roll = clamp(pilot_roll + servo_roll, -1, 1)
   
   --debug_params[0] = pilot_pitch
   --debug_params[1] = pilot_roll
end

if currentAP ~= AP then
  if AP ~= 2 then
	  
  else
  	  
  end
  
  currentAP = AP
  
end

-- 2) set surfaces angles from yoke_pitch and yoke_roll

-- AILERONS

local roll_corrected = yoke_roll_total - servo_roll

if	roll_corrected > 0
	then	ail_L =   aileron_max_def_down * roll_corrected
		    ail_R = - aileron_max_def_up * roll_corrected
	else	ail_L =   aileron_max_def_up * roll_corrected
		    ail_R = - aileron_max_def_down * roll_corrected
end

-- ELEVATOR
 
 local pitch_corrected = yoke_pitch_total - servo_pitch
 
if	pitch_corrected > 0
	then	elev_L = - elevator_max_def_up * pitch_corrected
		    elev_R =  - elevator_max_def_up * pitch_corrected 
	else	elev_L = - elevator_max_def_down * pitch_corrected
		    elev_R = - elevator_max_def_down * pitch_corrected
end

-- RUDDER

local yaw_corrected = yoke_yaw_total - servo_yaw

-- fixme: take left/right into account
if yoke_yaw_total > 0 then
  rudder = rudder_max_def_rr * yaw_corrected
else
  rudder = rudder_max_def_lr * yaw_corrected  
end

-- FLAPS

-- fixme: get extension angle from acf datarefs
-- fixme: get number of flaps from acf datarefs
for i=0,3 do 
  flaps[i] = flaps_deploy_ratio * 30.0
end

end

--

-- make a switchable menu entry , default is on 
add_macro(" CL Yoke" , "take_control(true)" , "take_control(false)" , "activate")


do_every_frame ("update_controls()")