#!/usr/bin/env python3

# Highlight numbers in a file using ANSI escape codes.

import re
import sys

styles = {}


def djb2(num):
    h = 5381

    for char in num:
        c = "0123456789abcdefABCDEFx".find(char) + 1
        h = h * 33 + c
        while h > 4294967295:  # Wrap to 32 bits manually
            h -= 4294967296

    return h


def make_style(num):
    """Create ANSI color style based on number value"""
    h = djb2(num)

    # If the number is very small (decimal -10 to 10), perturb hash
    if re.match(r"^-?[0-9]+$", num) and -10 <= int(num) <= 10:
        h = (h * 7919 + 1234567) % 4294967296

    # Mix hash into three different values
    r = (h * 3 + 123) % 256
    g = (h * 5 + 231) % 256
    b = (h * 7 + 77) % 256

    # Minimum brightness
    minv = 80
    range_val = 255 - minv

    r = minv + (r * range_val // 255)
    g = minv + (g * range_val // 255)
    b = minv + (b * range_val // 255)

    r = int(r) % 256
    g = int(g) % 256
    b = int(b) % 256

    style = f"\033[38;2;{r};{g};{b}m"

    # Big hex numbers (≥8 hex digits) → bold + underline
    if num.startswith("0x"):
        hex_part = num[2:]
        if len(hex_part) >= 8:
            style += "\033[1m\033[4m"

    return style


def process_line(line):
    """Process a single line of text to highlight numbers"""
    output = ""
    pos = 0

    # Process one character at a time
    while pos < len(line):
        # Check for negative numbers
        if line[pos] == "-" and pos < len(line) - 1:
            if re.match("[0-9]", line[pos + 1]):
                # Look ahead to see if it's a standalone negative number
                is_valid = True
                if pos > 0:
                    prev_char = line[pos - 1]
                    if re.match("[A-Za-z0-9_./]", prev_char):
                        is_valid = False

                if is_valid:
                    # Find the end of the number
                    num_start = pos
                    num_end = pos + 1
                    while num_end < len(line) and re.match("[0-9]", line[num_end]):
                        num_end += 1
                    num_end -= 1

                    # Check if it's a standalone number
                    if num_end < len(line) - 1:
                        next_char = line[num_end + 1]
                        if re.match("[A-Za-z0-9_./]", next_char):
                            is_valid = False

                    if is_valid:
                        num = line[num_start : num_end + 1]
                        if num not in styles:
                            styles[num] = make_style(num)

                        output += styles[num] + num + "\033[0m"
                        pos = num_end + 1
                        continue

        # Check for positive numbers (hex or decimal)
        if re.match("[0-9]", line[pos]):
            # Check if this could be a standalone number
            is_valid = True
            if pos > 0:
                prev_char = line[pos - 1]
                if re.match("[A-Za-z0-9_./]", prev_char):
                    is_valid = False

            if is_valid:
                # Check for hex numbers
                if (
                    pos < len(line) - 2
                    and line[pos : pos + 2] == "0x"
                    and pos + 2 < len(line)
                    and re.match("[0-9a-fA-F]", line[pos + 2])
                ):

                    # Find the end of the hex number
                    num_start = pos
                    num_end = pos + 2
                    while num_end < len(line) and re.match(
                        "[0-9a-fA-F]", line[num_end]
                    ):
                        num_end += 1
                    num_end -= 1

                else:
                    # Find the end of the decimal number
                    num_start = pos
                    num_end = pos
                    while num_end < len(line) and re.match("[0-9]", line[num_end]):
                        num_end += 1
                    num_end -= 1

                # Check if it's a standalone number
                if num_end < len(line) - 1:
                    next_char = line[num_end + 1]
                    if re.match("[A-Za-z0-9_./]", next_char):
                        is_valid = False

                if is_valid:
                    num = line[num_start : num_end + 1]
                    if num not in styles:
                        styles[num] = make_style(num)

                    output += styles[num] + num + "\033[0m"
                    pos = num_end + 1
                    continue

        # Not a number, just add the character
        output += line[pos]
        pos += 1

    return output


def main():
    """Process each line from input"""
    for line in sys.stdin:
        print(process_line(line.rstrip("\n")))


if __name__ == "__main__":
    main()
