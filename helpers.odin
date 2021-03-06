package glfw

import "core:fmt"
import "core:math"
import "core:strings"
import "core:runtime"

import bind "bindings"

/* Helpers */

// globals for persistent timing data, placeholder for "static" variables
_TimingStruct :: struct {
    t1, avg_dt, avg_dt2, last_frame_time : f64,
    num_samples, counter: int,
}
persistent_timing_data := _TimingStruct{0.0, 0.0, 0.0, 1.0/60, 60, 0};
last_measured_avg_frame_time: f64;

calculate_frame_timings :: proc(window: Window_Handle) {
    using persistent_timing_data;
    t2 := bind.GetTime();
    dt := t2-t1;
    t1 = t2;

    avg_dt += dt;
    avg_dt2 += dt*dt;
    counter += 1;

    last_frame_time = dt;

    if counter == num_samples || avg_dt > 1.0 {
        avg_dt  /= f64(counter);
        avg_dt2 /= f64(counter);
        std_dt := math.sqrt(avg_dt2 - avg_dt*avg_dt);
        ste_dt := std_dt/math.sqrt(f64(counter));

        last_measured_avg_frame_time = avg_dt;

        buf: [1024]u8;
        title := fmt.bprintf(buf[:], "frame timings: avg = %.3fms, std = %.3fms, ste = %.4fms. fps = %.1f\x00", 1e3*avg_dt, 1e3*std_dt, 1e3*ste_dt, 1.0/avg_dt);
        bind.SetWindowTitle(window, strings.unsafe_string_to_cstring(title));

        num_samples = int(1.0/avg_dt);
        avg_dt = 0.0;
        avg_dt2 = 0.0;
        counter = 0;
    }
}

calculate_frame_timings2 :: proc(window: Window_Handle, old_title: string) {
    using persistent_timing_data;
    t2 := bind.GetTime();
    dt := t2-t1;
    t1 = t2;

    avg_dt += dt;
    avg_dt2 += dt*dt;
    counter += 1;

    last_frame_time = dt;

    if counter == num_samples || avg_dt > 1.0 {
        avg_dt  /= f64(counter);
        avg_dt2 /= f64(counter);
        //std_dt := math.sqrt(avg_dt2 - avg_dt*avg_dt);
        //ste_dt := std_dt/math.sqrt(f64(num_samples));

        last_measured_avg_frame_time = avg_dt;

        buf: [1024]u8;
        title := fmt.bprintf(buf[:], "%s     fps = %.2f\x00", old_title, 1.0/avg_dt);
        bind.SetWindowTitle(window, strings.unsafe_string_to_cstring(title));

        num_samples = int(1.0/avg_dt);
        avg_dt = 0.0;
        avg_dt2 = 0.0;
        counter = 0;
    }
}

init_helper :: proc(resx := 1280, resy := 720, title := "Window title", version_major := 3, version_minor := 3, samples := 0, vsync := false, decorate := true, maximize := false) -> Window_Handle {
    //
    error_callback :: proc"c"(error: i32, desc: cstring) {
        context = runtime.default_context();
        fmt.printf("Error code %d: %s\n", error, desc);
    }
    bind.SetErrorCallback(error_callback);

    //
    if bind.Init() == bind.FALSE do return nil;

    //
    if samples > 0 do bind.WindowHint(bind.SAMPLES, i32(samples));
    if !decorate do bind.WindowHint(bind.DECORATED, 0);
    if maximize do bind.WindowHint(bind.MAXIMIZED, 1);
    bind.WindowHint(bind.CONTEXT_VERSION_MAJOR, i32(version_major));
    bind.WindowHint(bind.CONTEXT_VERSION_MINOR, i32(version_minor));
    bind.WindowHint(bind.OPENGL_PROFILE, bind.OPENGL_CORE_PROFILE);

    //
    window := create_window(int(resx), int(resy), title, nil, nil);
    if window == nil do return nil;

    //
    bind.MakeContextCurrent(window);
    bind.SwapInterval(i32(vsync));

    return window;
}

init_helper_map :: proc(resx := 1280, resy := 720, title := "Window title", swap_interval: int, window_attributes: map[Window_Attribute]i32, share: Window_Handle = nil, callback: proc"c"(error: i32, desc: cstring) = nil) -> Window_Handle {
    //
    error_callback :: proc"c"(error: i32, desc: cstring) {
        context = runtime.default_context();
        fmt.printf("Error code %d: %s\n", error, desc);
    }
    if callback == nil do bind.SetErrorCallback(error_callback);
    else do bind.SetErrorCallback(callback);

    //
    if bind.Init() == bind.FALSE do return nil;

    //
    for k, v in window_attributes {
        bind.WindowHint(i32(k), i32(v));
    }

    //
    window := create_window(int(resx), int(resy), title, nil, share);
    if window == nil do return nil;

    //
    bind.MakeContextCurrent(window);
    bind.SwapInterval(i32(swap_interval));

    return window;
}

set_proc_address :: proc(p: rawptr, name: cstring) {
    (cast(^rawptr)p)^ = bind.GetProcAddress(name);
}

