package clipboard

Data :: union {
	Text,
	Image,
}

Text :: string

Image :: struct {
	data:      []byte,
	mime_type: string,
}

get: proc() -> (Data, bool)
set: proc(_: Data)

@(init)
init :: proc "contextless" () {
	when ODIN_OS == .Linux {
		get = get_linux
		set = set_linux
	}
	when ODIN_OS == .Windows {
		get = get_windows
		set = set_windows
	}
	when ODIN_OS == .Darwin {
		get = get_mac
		set = set_mac
	}
}
