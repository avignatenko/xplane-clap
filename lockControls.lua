-----------------DO NOT EDIT BELOW THIS LINE-----------------------------
dataref("AP", "sim/cockpit/autopilot/autopilot_mode", "readonly")

dataref("pitch", "sim/joystick/yoke_pitch_ratio", "writable")
dataref("roll", "sim/joystick/yoke_roll_ratio", "writable")

local last_run = -1
local speed = 0.05 -- per/sec


function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

function check_AP()
	if AP == 2 then

		local now = os.clock();		
	
	    if last_run < 0 then last_run = now end
	    local delta = (now - last_run) * speed
        last_run = now
		
        if math.abs(pitch) > 0.001 then		
		  local pitch_sign = sign(pitch)
          pitch = pitch - pitch_sign * delta
		  if sign(pitch) ~= pitch_sign then pitch = 0.0 end
		end
		
		if math.abs(roll) > 0.001 then
		  local roll_sign = sign(roll)
          roll = roll - roll_sign * delta
		  if sign(roll) ~= roll_sign then roll = 0.0 end
		end
		
--	    set("sim/joystick/yoke_pitch_ratio", 0.0)
--		set("sim/joystick/yoke_roll_ratio", 0.0)

	else 
		last_run = -1
	end
end

do_every_frame ("check_AP()")

