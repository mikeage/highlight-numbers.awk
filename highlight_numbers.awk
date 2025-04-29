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

	# If the number is very small (decimal -10 to 10), perturb hash
	if ((num ~ /^-?[0-9]+$/) && (num + 0 <= 10) && (num + 0 >= -10)) {
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

	# Process one character at a time
	pos = 1
	while (pos <= length(line)) {
		# Check for negative numbers
		if (substr(line, pos, 1) == "-" && pos < length(line)) {
			if (substr(line, pos+1, 1) ~ /[0-9]/) {
				# Look ahead to see if it's a standalone negative number
				is_valid = 1
				if (pos > 1) {
					prev_char = substr(line, pos-1, 1)
					if (prev_char ~ /[A-Za-z0-9_\.\/]/)
						is_valid = 0
				}

				if (is_valid) {
					# Find the end of the number
					num_start = pos
					num_end = pos + 1
					while (num_end <= length(line) && substr(line, num_end, 1) ~ /[0-9]/)
						num_end++
					num_end--

					# Check if it's a standalone number
					if (num_end < length(line)) {
						next_char = substr(line, num_end+1, 1)
						if (next_char ~ /[A-Za-z0-9_\.\/]/)
							is_valid = 0
					}

					if (is_valid) {
						num = substr(line, num_start, num_end - num_start + 1)
						if (!(num in styles))
							styles[num] = make_style(num)

						output = output styles[num] num "\033[0m"
						pos = num_end + 1
						continue
					}
				}
			}
		}

		# Check for positive numbers (hex or decimal)
		if (substr(line, pos, 1) ~ /[0-9]/) {
			# Check if this could be a standalone number
			is_valid = 1
			if (pos > 1) {
				prev_char = substr(line, pos-1, 1)
				if (prev_char ~ /[A-Za-z0-9_\.\/]/)
					is_valid = 0
			}

			if (is_valid) {
				# Check for hex numbers
				if (pos < length(line) - 1 &&
					substr(line, pos, 2) == "0x" &&
					pos + 2 <= length(line) &&
					substr(line, pos+2, 1) ~ /[0-9a-fA-F]/) {

					# Find the end of the hex number
					num_start = pos
					num_end = pos + 2
					while (num_end <= length(line) && substr(line, num_end, 1) ~ /[0-9a-fA-F]/)
						num_end++
					num_end--

				} else {
					# Find the end of the decimal number
					num_start = pos
					num_end = pos
					while (num_end <= length(line) && substr(line, num_end, 1) ~ /[0-9]/)
						num_end++
					num_end--
				}

				# Check if it's a standalone number
				if (num_end < length(line)) {
					next_char = substr(line, num_end+1, 1)
					if (next_char ~ /[A-Za-z0-9_\.\/]/)
						is_valid = 0
				}

				if (is_valid) {
					num = substr(line, num_start, num_end - num_start + 1)
					if (!(num in styles))
						styles[num] = make_style(num)

					output = output styles[num] num "\033[0m"
					pos = num_end + 1
					continue
				}
			}
		}

		# Not a number, just add the character
		output = output substr(line, pos, 1)
		pos++
	}

	print output
}

