#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b);

// A longer lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT int sum_long_running(int a, int b);

FFI_PLUGIN_EXPORT int subtract(int a, int b);

FFI_PLUGIN_EXPORT const char* hello();

FFI_PLUGIN_EXPORT char** get_languages(int* out_len);
FFI_PLUGIN_EXPORT void free_languages(char** arr, int len);

FFI_PLUGIN_EXPORT char** get_map(int* out_pairs);
FFI_PLUGIN_EXPORT void free_map(char** arr, int pairs);

struct Coordinate
{
    double latitude;
    double longitude;
};

struct Place
{
    char *name;
    struct Coordinate coordinate;
};

FFI_PLUGIN_EXPORT struct Coordinate create_coordinate(double latitude, double longitude);
FFI_PLUGIN_EXPORT struct Place create_place(char *name, double latitude, double longitude);

FFI_PLUGIN_EXPORT double distance(struct Coordinate, struct Coordinate);

FFI_PLUGIN_EXPORT char *reverse(char *str, int length);