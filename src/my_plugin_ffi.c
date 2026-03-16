#include "my_plugin_ffi.h"

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b) { return a + b; }

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT int sum_long_running(int a, int b) {
    // Simulate work.
#if _WIN32
    Sleep(5000);
#else
    usleep(5000 * 1000);
#endif
    return a + b;
}

FFI_PLUGIN_EXPORT int subtract(int a, int b) {
    return a - b;
}

FFI_PLUGIN_EXPORT const char *hello() {
    return "Hello from C!";
}

FFI_PLUGIN_EXPORT char **get_languages(int *out_len) {
    const char *items[] = {"java", "c++", "python"};
    int len = 3;
    char **arr = (char **) malloc(sizeof(char *) * len);
    if (!arr) {
        if (out_len)
            *out_len = 0;
        return NULL;
    }
    for (int i = 0; i < len; ++i) {
        size_t l = strlen(items[i]) + 1;
        arr[i] = (char *) malloc(l);
        if (arr[i])
            memcpy(arr[i], items[i], l);
    }
    if (out_len)
        *out_len = len;
    return arr;
}

FFI_PLUGIN_EXPORT void free_languages(char **arr, int len) {
    if (!arr)
        return;
    for (int i = 0; i < len; ++i) {
        free(arr[i]);
    }
    free(arr);
}

FFI_PLUGIN_EXPORT char **get_map(int *out_pairs) {
    // Example map: { "name": "flutter", "language": "dart", "version": "3.0" }
    const char *items[] = {
            "name", "flutter",
            "language", "dart",
            "version", "3.0"};
    const int pairs = 3;
    const int total = pairs * 2;

    char **arr = (char **) malloc(sizeof(char *) * total);
    if (!arr) {
        if (out_pairs)
            *out_pairs = 0;
        return NULL;
    }

    for (int i = 0; i < total; ++i) {
        size_t l = strlen(items[i]) + 1;
        arr[i] = (char *) malloc(l);
        if (arr[i])
            memcpy(arr[i], items[i], l);
    }

    if (out_pairs)
        *out_pairs = pairs;
    return arr;
}

FFI_PLUGIN_EXPORT void free_map(char **arr, int pairs) {
    if (!arr)
        return;
    int total = pairs * 2;
    for (int i = 0; i < total; ++i) {
        free(arr[i]);
    }
    free(arr);
}

FFI_PLUGIN_EXPORT struct Coordinate create_coordinate(double latitude, double longitude) {
    struct Coordinate coordinate;
    coordinate.latitude = latitude;
    coordinate.longitude = longitude;
    return coordinate;
}

FFI_PLUGIN_EXPORT struct Place create_place(char *name, double latitude, double longitude) {
    struct Place place;
    place.name = name;
    place.coordinate = create_coordinate(latitude, longitude);
    return place;
}

FFI_PLUGIN_EXPORT double distance(struct Coordinate c1, struct Coordinate c2) {
    // This is a dummy implementation. In a real implementation, you would calculate
    // the distance between the two coordinates using the Haversine formula or similar.
    double lat_diff = c2.latitude - c1.latitude;
    double lon_diff = c2.longitude - c1.longitude;
    return sqrt(lat_diff * lat_diff + lon_diff * lon_diff);
}

FFI_PLUGIN_EXPORT char *reverse(char *str, int length) {
    char *reversed = (char *) malloc((length + 1) * sizeof(char));

    for (int i = 0; i < length; ++i) {
        reversed[i] = str[length - 1 - i];
    }
    reversed[length] = '\0';
    return reversed;
}

FFI_PLUGIN_EXPORT void getBaseVersion(char ver[]) {
    const char *version = "1.0.0";
    strcpy_s(ver, strlen(version) + 1, version);
}

// Function that takes a callback
FFI_PLUGIN_EXPORT void call_callback(int value, IntCallback callback) {
    callback(value + 8);
}
