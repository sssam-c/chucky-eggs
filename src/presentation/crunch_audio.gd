class_name CrunchAudio
extends RefCounted

const MIX_RATE := 44100


static func lever() -> AudioStreamWAV:
	return _build_stream(0.16, 211, func(t: float, sample_index: int) -> float:
		var latch := sin(TAU * 185.0 * t) * exp(-34.0 * t) * 0.48
		var metal := sin(TAU * 1420.0 * t) * exp(-42.0 * t) * 0.16
		var travel := _noise(sample_index, 211) * _pulse(t, 0.025, 0.065) * 0.11
		var stop_time := maxf(t - 0.082, 0.0)
		var stop := sin(TAU * 126.0 * stop_time) * _pulse(t, 0.082, 0.065) * 0.52
		var stop_click := _noise(sample_index, 223) * _pulse(t, 0.082, 0.018) * 0.30
		return (latch + metal + travel + stop + stop_click) * 0.72
	)


static func impact() -> AudioStreamWAV:
	return _build_stream(0.16, 11, func(t: float, sample_index: int) -> float:
		var envelope := exp(-24.0 * t)
		var metal := sin(TAU * 1720.0 * t) * 0.24 * exp(-17.0 * t)
		var body := sin(TAU * 310.0 * t) * 0.19 * exp(-22.0 * t)
		var grit := _noise(sample_index, 11) * 0.58 * envelope
		var chip := _noise(sample_index, 29) * _pulse(t, 0.033, 0.014) * 0.32
		return (metal + body + grit + chip) * 0.78
	)


static func shell_hit() -> AudioStreamWAV:
	return _build_stream(0.14, 307, func(t: float, sample_index: int) -> float:
		# A close, dry shell fracture: one hard snap followed by irregular brittle
		# chips. Keep the low body quiet so the spoon does not read as a metal thud.
		var snap := _noise(sample_index, 307) * exp(-78.0 * t) * 0.82
		var first_chip := _noise(sample_index, 331) * _pulse(t, 0.017, 0.018) * 0.62
		var second_chip := _noise(sample_index, 353) * _pulse(t, 0.043, 0.024) * 0.38
		var shell_ring := sin(TAU * 2380.0 * t) * exp(-42.0 * t) * 0.16
		var fine_grit := _noise(sample_index, 379) * _pulse(t, 0.055, 0.055) * 0.14
		return (snap + first_chip + second_chip + shell_ring + fine_grit) * 0.74
	)


static func echo() -> AudioStreamWAV:
	return _build_stream(0.20, 101, func(t: float, sample_index: int) -> float:
		var sympathetic_ring := sin(TAU * 1180.0 * t) * exp(-15.0 * t) * 0.26
		var glassy_second := sin(TAU * 1780.0 * t) * exp(-23.0 * t) * 0.15
		var shell_tick := _noise(sample_index, 101) * exp(-32.0 * t) * 0.50
		var chirp_time := maxf(t - 0.055, 0.0)
		var chirp := sin(TAU * (1350.0 + chirp_time * 1700.0) * chirp_time) * _pulse(t, 0.055, 0.10) * 0.12
		return (sympathetic_ring + glassy_second + shell_tick + chirp) * 0.72
	)


static func shuffle() -> AudioStreamWAV:
	return _build_stream(0.24, 131, func(t: float, sample_index: int) -> float:
		var chirp := sin(TAU * (1160.0 + t * 2100.0) * t) * _pulse(t, 0.0, 0.10) * 0.20
		var scrape := _noise(sample_index, 131) * _pulse(t, 0.045, 0.12) * 0.18
		var first_knock := sin(TAU * 178.0 * t) * exp(-26.0 * t) * 0.30
		var landing_time := maxf(t - 0.145, 0.0)
		var landing := sin(TAU * 132.0 * landing_time) * _pulse(t, 0.145, 0.085) * 0.42
		return (chirp + scrape + first_knock + landing) * 0.72
	)


static func hatch() -> AudioStreamWAV:
	return _build_stream(0.38, 23, func(t: float, sample_index: int) -> float:
		var first_crack := _noise(sample_index, 23) * exp(-31.0 * t) * 0.72
		var second_crack := _noise(sample_index, 47) * _pulse(t, 0.055, 0.032) * 0.70
		var shell_rattle := _noise(sample_index, 71) * _pulse(t, 0.12, 0.11) * 0.33
		var pop := sin(TAU * 126.0 * t) * exp(-13.0 * t) * 0.34
		var chirp_time := maxf(t - 0.17, 0.0)
		var chirp := sin(TAU * (1550.0 + chirp_time * 2400.0) * chirp_time) * _pulse(t, 0.17, 0.15) * 0.13
		return (first_crack + second_crack + shell_rattle + pop + chirp) * 0.76
	)


static func score() -> AudioStreamWAV:
	return _build_stream(0.34, 173, func(t: float, sample_index: int) -> float:
		var coin := _noise(sample_index, 173) * exp(-52.0 * t) * 0.20
		var first := sin(TAU * 880.0 * t) * exp(-14.0 * t) * 0.24
		var second_time := maxf(t - 0.065, 0.0)
		var second := sin(TAU * 1174.0 * second_time) * _pulse(t, 0.065, 0.20) * 0.25
		var third_time := maxf(t - 0.125, 0.0)
		var third := sin(TAU * 1568.0 * third_time) * _pulse(t, 0.125, 0.20) * 0.22
		var body := sin(TAU * 220.0 * t) * exp(-18.0 * t) * 0.15
		return (coin + first + second + third + body) * 0.78
	)


static func belt() -> AudioStreamWAV:
	return _build_stream(0.20, 37, func(t: float, sample_index: int) -> float:
		var motor := sin(TAU * 72.0 * t) * exp(-9.0 * t) * 0.28
		var first_clunk := sin(TAU * 190.0 * t) * exp(-32.0 * t) * 0.44
		var second_time := maxf(t - 0.09, 0.0)
		var second_clunk := sin(TAU * 165.0 * second_time) * _pulse(t, 0.09, 0.07) * 0.34
		var grit := _noise(sample_index, 37) * exp(-16.0 * t) * 0.08
		return motor + first_clunk + second_clunk + grit
	)


static func loss() -> AudioStreamWAV:
	return _build_stream(0.36, 53, func(t: float, sample_index: int) -> float:
		var falling := sin(TAU * (540.0 - t * 760.0) * t) * _pulse(t, 0.0, 0.18) * 0.13
		var smash := _noise(sample_index, 53) * _pulse(t, 0.16, 0.055) * 0.82
		var debris := _noise(sample_index, 97) * _pulse(t, 0.20, 0.14) * 0.34
		var thud_time := maxf(t - 0.16, 0.0)
		var thud := sin(TAU * 84.0 * thud_time) * _pulse(t, 0.16, 0.13) * 0.42
		return (falling + smash + debris + thud) * 0.72
	)


static func pipe() -> AudioStreamWAV:
	return _build_stream(0.18, 89, func(t: float, sample_index: int) -> float:
		var tube := sin(TAU * 420.0 * t) * exp(-15.0 * t) * 0.18
		var knock_time := maxf(t - 0.055, 0.0)
		var knock := sin(TAU * 148.0 * knock_time) * _pulse(t, 0.055, 0.11) * 0.46
		var grit := _noise(sample_index, 89) * _pulse(t, 0.055, 0.04) * 0.18
		return tube + knock + grit
	)


static func ui_focus() -> AudioStreamWAV:
	return _build_stream(0.055, 401, func(t: float, sample_index: int) -> float:
		var tick := _noise(sample_index, 401) * exp(-62.0 * t) * 0.16
		var enamel := sin(TAU * 1540.0 * t) * exp(-48.0 * t) * 0.13
		return (tick + enamel) * 0.58
	)


static func ui_press() -> AudioStreamWAV:
	return _build_stream(0.075, 419, func(t: float, sample_index: int) -> float:
		var latch := sin(TAU * 190.0 * t) * exp(-40.0 * t) * 0.30
		var click := _noise(sample_index, 419) * exp(-68.0 * t) * 0.23
		return (latch + click) * 0.62
	)


static func ui_confirm() -> AudioStreamWAV:
	return _build_stream(0.18, 433, func(t: float, sample_index: int) -> float:
		var coin := _noise(sample_index, 433) * exp(-66.0 * t) * 0.15
		var first := sin(TAU * 880.0 * t) * exp(-23.0 * t) * 0.19
		var second_time := maxf(t - 0.052, 0.0)
		var second := sin(TAU * 1320.0 * second_time) * _pulse(t, 0.052, 0.11) * 0.18
		return (coin + first + second) * 0.66
	)


static func ui_reject() -> AudioStreamWAV:
	return _build_stream(0.19, 461, func(t: float, sample_index: int) -> float:
		var first := sin(TAU * 132.0 * t) * exp(-31.0 * t) * 0.31
		var first_click := _noise(sample_index, 461) * exp(-70.0 * t) * 0.18
		var second_time := maxf(t - 0.082, 0.0)
		var second := sin(TAU * 112.0 * second_time) * _pulse(t, 0.082, 0.08) * 0.34
		return (first + first_click + second) * 0.68
	)


static func ui_panel() -> AudioStreamWAV:
	return _build_stream(0.22, 487, func(t: float, sample_index: int) -> float:
		var latch := sin(TAU * 164.0 * t) * exp(-30.0 * t) * 0.25
		var slide := _noise(sample_index, 487) * _pulse(t, 0.025, 0.12) * 0.07
		var stop_time := maxf(t - 0.135, 0.0)
		var stop := sin(TAU * 118.0 * stop_time) * _pulse(t, 0.135, 0.075) * 0.28
		return (latch + slide + stop) * 0.62
	)


static func _build_stream(duration: float, seed: int, sampler: Callable) -> AudioStreamWAV:
	var sample_count := int(ceil(duration * MIX_RATE))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var t := float(sample_index) / float(MIX_RATE)
		var sample: float = clampf(sampler.call(t, sample_index + seed), -1.0, 1.0)
		pcm.encode_s16(sample_index * 2, int(sample * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = pcm
	return stream


static func _noise(sample_index: int, seed: int) -> float:
	var value := sin(float(sample_index * 127 + seed * 311) * 12.9898) * 43758.5453
	return (value - floor(value)) * 2.0 - 1.0


static func _pulse(t: float, start: float, duration: float) -> float:
	if t < start or t >= start + duration:
		return 0.0
	var local_t := (t - start) / duration
	return sin(PI * local_t) * exp(-2.4 * local_t)
