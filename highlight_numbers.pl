#!/usr/bin/perl

# Highlight numbers in a file using ANSI escape codes.

use strict;
use warnings;

my %styles;

sub djb2 {
    my $num = shift;
    my $h = 5381;
    
    for my $i (0..length($num)-1) {
        my $c = index("0123456789abcdefABCDEFx", substr($num, $i, 1)) + 1; 
        $h = ($h * 33 + $c);
        while ($h > 4294967295) { $h -= 4294967296; } # Wrap to 32 bits manually
    }
    
    return $h;
}

# Create ANSI color style based on number value
sub make_style {
    my $num = shift;
    my $h = djb2($num);
    
    # If the number is very small (decimal -10 to 10), perturb hash
    if ($num =~ /^-?[0-9]+$/ && $num + 0 <= 10 && $num + 0 >= -10) {
        $h = ($h * 7919 + 1234567) % 4294967296;
    }
    
    # Mix hash into three different values
    my $r = ($h * 3 + 123) % 256;
    my $g = ($h * 5 + 231) % 256;
    my $b = ($h * 7 + 77) % 256;
    
    # Minimum brightness
    my $minv = 80;
    my $range = 255 - $minv;
    
    $r = $minv + ($r * $range / 255);
    $g = $minv + ($g * $range / 255);
    $b = $minv + ($b * $range / 255);
    
    $r = int($r) % 256;
    $g = int($g) % 256;
    $b = int($b) % 256;
    
    my $style = sprintf("\033[38;2;%d;%d;%dm", $r, $g, $b);
    
    # Big hex numbers (≥8 hex digits) → bold + underline
    if ($num =~ /^0x/) {
        my $hex_part = substr($num, 2);
        if (length($hex_part) >= 8) {
            $style .= "\033[1m\033[4m";
        }
    }
    
    return $style;
}

# Process each line from input
while (my $line = <>) {
    chomp $line;
    my $output = "";
    my $pos = 0;
    
    # Process one character at a time
    while ($pos < length($line)) {
        # Check for negative numbers
        if (substr($line, $pos, 1) eq "-" && $pos < length($line) - 1) {
            if (substr($line, $pos+1, 1) =~ /[0-9]/) {
                # Look ahead to see if it's a standalone negative number
                my $is_valid = 1;
                if ($pos > 0) {
                    my $prev_char = substr($line, $pos-1, 1);
                    if ($prev_char =~ /[A-Za-z0-9_\.\/]/) {
                        $is_valid = 0;
                    }
                }
                
                if ($is_valid) {
                    # Find the end of the number
                    my $num_start = $pos;
                    my $num_end = $pos + 1;
                    while ($num_end < length($line) && substr($line, $num_end, 1) =~ /[0-9]/) {
                        $num_end++;
                    }
                    $num_end--;
                    
                    # Check if it's a standalone number
                    if ($num_end < length($line) - 1) {
                        my $next_char = substr($line, $num_end+1, 1);
                        if ($next_char =~ /[A-Za-z0-9_\.\/]/) {
                            $is_valid = 0;
                        }
                    }
                    
                    if ($is_valid) {
                        my $num = substr($line, $num_start, $num_end - $num_start + 1);
                        if (!exists $styles{$num}) {
                            $styles{$num} = make_style($num);
                        }
                        
                        $output .= $styles{$num} . $num . "\033[0m";
                        $pos = $num_end + 1;
                        next;
                    }
                }
            }
        }
        
        # Check for positive numbers (hex or decimal)
        if (substr($line, $pos, 1) =~ /[0-9]/) {
            # Check if this could be a standalone number
            my $is_valid = 1;
            if ($pos > 0) {
                my $prev_char = substr($line, $pos-1, 1);
                if ($prev_char =~ /[A-Za-z0-9_\.\/]/) {
                    $is_valid = 0;
                }
            }
            
            if ($is_valid) {
                my $num_start = $pos;
                my $num_end;
                
                # Check for hex numbers
                if ($pos < length($line) - 2 && 
                    substr($line, $pos, 2) eq "0x" && 
                    substr($line, $pos+2, 1) =~ /[0-9a-fA-F]/) {
                    
                    # Find the end of the hex number
                    $num_start = $pos;
                    $num_end = $pos + 2;
                    while ($num_end < length($line) && substr($line, $num_end, 1) =~ /[0-9a-fA-F]/) {
                        $num_end++;
                    }
                    $num_end--;
                    
                } else {
                    # Find the end of the decimal number
                    $num_end = $pos;
                    while ($num_end < length($line) && substr($line, $num_end, 1) =~ /[0-9]/) {
                        $num_end++;
                    }
                    $num_end--;
                }
                
                # Check if it's a standalone number
                if ($num_end < length($line) - 1) {
                    my $next_char = substr($line, $num_end+1, 1);
                    if ($next_char =~ /[A-Za-z0-9_\.\/]/) {
                        $is_valid = 0;
                    }
                }
                
                if ($is_valid) {
                    my $num = substr($line, $num_start, $num_end - $num_start + 1);
                    if (!exists $styles{$num}) {
                        $styles{$num} = make_style($num);
                    }
                    
                    $output .= $styles{$num} . $num . "\033[0m";
                    $pos = $num_end + 1;
                    next;
                }
            }
        }
        
        # Not a number, just add the character
        $output .= substr($line, $pos, 1);
        $pos++;
    }
    
    print "$output\n";
}

