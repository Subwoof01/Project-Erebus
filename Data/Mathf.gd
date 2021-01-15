extends Node

func smooth_start2(t):
	return t*t

func smooth_start3(t):
	return t*t*t

func smooth_startN(t, n):
	var a = t
	for i in range(n):
		a *= t
	return a

func smooth_stop2(t):
	return 1-((1-t)*(1-t))

func smooth_stop3(t):
	return 1-((1-t)*(1-t)*(1-t))

func smooth_stopN(t, n):
	var a = (1-t)
	for i in range(n):
		a *= (1-t)
	return 1 - a

func mix(a, b, weight_b, t):
	return a + weight_b * (b-a)

func crossfade(a, b, t):
	return a+t*(b-a)

func normalise(x, max_v, min_v=0):
	return (x-min_v)/(max_v-min_v)

func randv_circle(p_min_radius = 1.0, p_max_radius = 1.0):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var r2_max = p_max_radius * p_max_radius
	var r2_min = p_min_radius * p_min_radius
	var r = sqrt(rng.randf() * (r2_max - r2_min) + r2_min)
	var t = rng.randf() * (PI * 2)
	return Vector2(r * cos(t), r * sin(t))
