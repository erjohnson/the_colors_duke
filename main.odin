package the_colors_duke

import "core:fmt"
import "core:io"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:math"

write_svg_header :: proc(w: io.Writer, rows: int) {
	fmt.wprintln(w, `<?xml version="1.0" standalone="no"?>`)
	fmt.wprintfln(w, `<svg width="300" height="{0:v}" version="1.1" xmlns="http://www.w3.org/2000/svg">`, rows * 75)
}

write_svg_recs :: proc(w: io.Writer, colors: []string) {
	x := 0
	y := 0
	for c in colors {
		fmt.wprintfln(w, `<rect x="{0:v}" y="{1:v}" width="75" height="75" fill="#{2:v}" />`, x, y, c)
		x += 75
		if x >= 300 {
			y += 75
			x = 0
		}
	}
}

write_svg_footer :: proc(w: io.Writer) {
	fmt.wprintln(w, `</svg>`)
}

main :: proc() {
	cwd := os.get_current_directory()

	dir_pal := filepath.join([]string{cwd, "palettes"})

	f, err := os.open(dir_pal)
	defer os.close(f)

	if err != os.ERROR_NONE {
		fmt.eprintln("Could not open directory for reading", err)
		os.exit(1)
	}

	fis: []os.File_Info
	defer os.file_info_slice_delete(fis)

	fis, err = os.read_dir(f, -1)
	if err != os.ERROR_NONE {
		fmt.eprintln("Could not read directory", err)
		os.exit(2)
	}

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	w := strings.to_writer(&b)

	for fi in fis {
		if strings.has_suffix(fi.name, ".txt") {
			data, ok := os.read_entire_file_from_filename(fi.fullpath)
			if !ok {
				fmt.eprintln("Failed to load the file!")
				return
			}
			defer delete(data)

			strings.builder_reset(&b)

			contents := strings.trim_right_space(string(data))
			colors := strings.split_lines(contents)
			defer delete(colors)

			num_colors := len(colors)
			num_rows := 1

			if (num_colors % 4) != 0 {
				num_rows = len(colors) / 4 + 1
			}

			write_svg_header(w, num_rows)
			write_svg_recs(w, colors)
			write_svg_footer(w)
			os.write_entire_file(fmt.tprintf("%s/%s.svg", dir_pal, strings.trim_suffix(fi.name, ".txt")), b.buf[:])
		}
	}
}
