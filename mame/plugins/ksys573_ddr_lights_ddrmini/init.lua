-- license:BSD-3-Clause
-- copyright-holders:windyfairy/987123879113
local exports = {
	name = 'ksys573_ddr_lights_ddrmini',
	version = '0.0.1',
	description = 'Konami System 573 Dance Dance Revolution Lights for DDR Classic Mini plugin',
	license = 'BSD-3-Clause',
	author = { name = 'windyfairy/987123879113' }
}

local ksys573_ddr_lights_ddrmini = exports

function ksys573_ddr_lights_ddrmini.startplugin()
	local function write_to_file(filename, data)
		local file, err = io.open(filename, 'ab')
		if file then
			io.output(file)
			io.write(data)
			io.close(file)
		else
			emu.print_error(err)
		end
	end

	local function frame_done()
		local p1_foot_up = manager.machine.output:get_value("foot 1p up")
		local p1_foot_left = manager.machine.output:get_value("foot 1p left")
		local p1_foot_right = manager.machine.output:get_value("foot 1p right")
		local p1_foot_down = manager.machine.output:get_value("foot 1p down")
		local p2_foot_up = manager.machine.output:get_value("foot 2p up")
		local p2_foot_left = manager.machine.output:get_value("foot 2p left")
		local p2_foot_right = manager.machine.output:get_value("foot 2p right")
		local p2_foot_down = manager.machine.output:get_value("foot 2p down")
		local body_right_low = manager.machine.output:get_value("body right low")
		local body_left_low = manager.machine.output:get_value("body left low")
		local body_left_high = manager.machine.output:get_value("body left high")
		local body_right_high = manager.machine.output:get_value("body right high")
		local speaker = manager.machine.output:get_value("speaker")
		local p1_start = manager.machine.output:get_value("start 1p") -- Custom for Bemani build
		local p2_start = manager.machine.output:get_value("start 2p") -- Custom for Bemani build

		write_to_file('/sys/class/leds/button1/brightness', p1_start)
		write_to_file('/sys/class/leds/button2/brightness', p1_start)
		write_to_file('/sys/class/leds/button3/brightness', p1_start)
		write_to_file('/sys/class/leds/button4/brightness', p2_start)
		write_to_file('/sys/class/leds/button5/brightness', p2_start)
		write_to_file('/sys/class/leds/button6/brightness', p2_start)
		write_to_file('/sys/class/leds/yellow1/brightness', body_left_low)
		write_to_file('/sys/class/leds/yellow2/brightness', body_right_low)
		write_to_file('/sys/class/leds/red1/brightness', body_left_high)
		write_to_file('/sys/class/leds/red2/brightness', body_right_high)
		write_to_file('/sys/class/leds/speaker_l/brightness', speaker)
		write_to_file('/sys/class/leds/speaker_r/brightness', speaker)

		write_to_file('/dev/input/hidraw_p1', string.char(0x05, p1_foot_right, p1_foot_down, p1_foot_left, p1_foot_up))
		write_to_file('/dev/input/hidraw_p2', string.char(0x05, p2_foot_right, p2_foot_down, p2_foot_left, p2_foot_up))
	end

	emu.register_frame_done(frame_done)
end

return exports
