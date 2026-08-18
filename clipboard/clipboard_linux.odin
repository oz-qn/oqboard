#+private
package clipboard

import "core:fmt"
import "core:os"
import "core:strings"

Backend :: enum u8 {
	Wayland,
	x11,
}

backend: Backend

get_linux :: proc() -> (Data, bool) {
	if backend == nil {
		found: bool
		backend, found = get_backend()
		if !found {
			fmt.eprintln("Could not find linux backend for clipboard.")
			return "", false
		}
	}
	switch backend {
	case .Wayland:
		state, stdout, stderr, err := os.process_exec(
			os.Process_Desc{command = []string{"wl-paste", "--list-types"}},
			context.temp_allocator,
		)

		if err != os.ERROR_NONE || !state.success {
			delete(stdout)
			delete(stderr)
			fmt.eprintln("Clipboard data type could not be recognized.")
			return "", false
		}

		found_image: bool = false
		mime_type: string = ""
		found_text: bool = false

		type_string := string(stdout)
		types := strings.split_lines(type_string, context.temp_allocator)
		for type in types {
			if type == "text/plain" {
				found_text = true
			}
			if type == "image/png" || type == "image/jpg" || type == "image/jpeg" {
				found_image = true
				mime_type = type
				break
			}
			if type == "text/uri-list" {
				found_text = true
			}
		}

		if found_image {
			if img_data, ok := get_wayland_image(mime_type); ok {
				return Image{img_data, mime_type}, true
			}
			return nil, false
		} else if found_text {
			if txt, ok := get_wayland_text(); ok {
				return txt, true
			}
			return nil, false
		}

		delete(stderr)
	case .x11:

	}

	return nil, false
}

set_linux :: proc(data: Data) {

}

get_backend :: proc() -> (Backend, bool) {
	if os.get_env_alloc("WAYLAND_DISPLAY", context.temp_allocator) != "" {
		return .Wayland, true
	} else if os.get_env_alloc("DISPLAY", context.temp_allocator) != "" {
		return .x11, true
	} else {
		return nil, false
	}
}


get_wayland_image :: proc(mime_type: string) -> ([]u8, bool) {
	mime := fmt.tprintf("-t{}", mime_type)
	state, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"wl-paste", mime}},
		context.temp_allocator,
	)

	if err != os.ERROR_NONE || !state.success {
		return nil, false
	}

	return stdout, true
}

get_wayland_text :: proc() -> (string, bool) {
	state, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"wl-paste", "--no-newline"}},
		context.temp_allocator,
	)

	if err != os.ERROR_NONE || !state.success {
		delete(stdout)
		delete(stderr)
		return "", false
	}

	return string(stdout), true
}
