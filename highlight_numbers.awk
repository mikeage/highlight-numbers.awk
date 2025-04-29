#!/usr/bin/awk -f

# Highlight numbers in a file using ANSI escape codes.
# Compatible with mawk (so it works on the default ubuntu docker image)

function djb2(num, i, c, h) {
	h = 5381
	for (i = 1; i <= length(num); i++) {
		c = index("0123456789abcdefABCDEFx", substr(num, i, 1))
		h = (h * 33 + c)
		while (h > 4294967295) h -= 4294967296 # Wrap to 32 bits manually
	}
	return h
}

function make_style(num, h, r, g, b, minv, range) {
	h = djb2(num)

	# If the number is very small (decimal 0-10), perturb hash
	if (num ~ /^[0-9]+$/ && num + 0 <= 10) {
		h = (h * 7919 + 1234567) % 4294967296
	}

	# Mix hash into three different values
	r = (h * 3 + 123) % 256
	g = (h * 5 + 231) % 256
	b = (h * 7 + 77) % 256

	# Minimum brightness
	minv = 80
	range = 255 - minv

	r = minv + (r * range / 255)
	g = minv + (g * range / 255)
	b = minv + (b * range / 255)

	r = int(r) % 256
	g = int(g) % 256
	b = int(b) % 256

	style = sprintf("\033[38;2;%d;%d;%dm", r, g, b)

	# Big hex numbers (≥8 hex digits) → bold + underline
	if (match(num, /^0x[0-9a-fA-F]{8,}$/)) {
		style = style "\033[1m\033[4m"
	}

	return style
}

{
	line = $0
	output = ""

	while (match(line, /(0x[0-9a-fA-F]+|[0-9]+)/)) {
		pre = substr(line, 1, RSTART - 1)
		num = substr(line, RSTART, RLENGTH)
		post = substr(line, RSTART + RLENGTH)

		if (!(num in styles))
			styles[num] = make_style(num)

		output = output pre styles[num] num "\033[0m"

		line = post
	}
	output = output line
	print output
}
