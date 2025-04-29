# `highlight_numbers.awk` 🎨🔢

A lightweight `awk` script for colorizing numbers in any text stream — especially useful for inspecting `strace`, logs, memory addresses, file descriptors, or any output with numeric data.

This script highlights every numeric value (both hexadecimal and decimal), assigning each a **deterministic, bright, unique RGB foreground color**.  

Large hexadecimal numbers (e.g., 64-bit memory addresses) are also **bold and underlined** to make them stand out further.

Supports:
- ✅ 24-bit ANSI color output
- ✅ Deterministic per-number coloring
- ✅ Foreground colors only (no background noise)
- ✅ Bold + underline for large hex values
- ✅ Fast, line-safe processing (no duplication, no corruption)
- ✅ Fully compatible with [`mawk`](https://invisible-island.net/mawk/) and `gawk`

---

## ✨ Example

```bash
strace -e trace=memory,file ./hello-world 2>&1 | highlight_numbers.awk
```

Before:

```
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xf7ffd000
```

After:

* 8192 → colored uniquely
* 0xf7ffd000 → colored + bold + underlined
* Same number repeated later? Same color again!

## 📦 Installation


Just clone the repo and make the script executable:

```bash
git clone https://github.com/mikeage/highlight-numbers
cd highlight-numbers
chmod +x highlight_numbers.awk
```

Optional: copy to a system-wide location:

```bash
sudo cp highlight_numbers.awk /usr/local/bin/highlight-numbers.awk
```

## 🧠 How it works

* Uses a DJB2 hash for each number
* Maps the hash to an RGB triplet
* Ensures minimum brightness so no colors are dark or invisible
* Big hex numbers are bold+underlined for visibility
* Built-in tweaks to distinguish small decimal values (like 0, 1, 3)

## ✅ Compatibility

POSIX-compliant

Works with:
* mawk
* gawk

No dependencies other than a standard awk interpreter

## 🔒 Limitations

* ANSI color codes are supported in most modern terminals (e.g. xterm, iTerm2, gnome-terminal, wezterm). If you're on an older terminal, 24-bit color may not display correctly.
* Does not handle multiline numbers (e.g., wrapped across lines)
* Doesn't parse structure (e.g., JSON nesting), just colors numbers in stream

## 🛠 TODO

 * Add flag support (--bold-only, --underline-only, etc.)
 * Optionally dump a color legend after processing
 * Group similar ranges (e.g., mmap-related) with soft background shades

## 📝 License

MIT License.

Enjoy, and feel free to fork or improve!

## 👤 Author

Created by Mike Miller + gpt-4o.

Inspired by tools like colout, strace-analyzer, and too much staring at monochrome logs.
