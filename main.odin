package main

import "core:fmt"
import "core:mem"

DEBUG :: true

main :: proc() {
	when DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintfln("=== %v allocations not freed: ===", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintfln("- %v bytes @ %v", entry.size, entry.location)
				}
				if len(track.bad_free_array) > 0 {
					fmt.eprintfln("--- %v incorrect frees: ===", len(track.bad_free_array))
					for entry in track.bad_free_array {
						fmt.eprintfln("- %p @ %v", entry.memory, entry.location)
					}
				}
				mem.tracking_allocator_destroy(&track)
			}
		}
	}

	app_init()

	for app_should_run() {
		app_update()
		app_draw()
		free_all(context.temp_allocator)
	}

	app_exit()

}
