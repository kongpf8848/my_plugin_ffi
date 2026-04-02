// software_info.h
// Windows Installed Software Enumeration DLL Header

#ifndef SOFTWARE_INFO_H
#define SOFTWARE_INFO_H

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0601
#endif
#ifndef WINVER
#define WINVER 0x0601
#endif

#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Software Enumeration Functions
// ============================================================================

// Software information structure
#pragma pack(push, 1)
typedef struct _SOFTWARE_INFO {
    char name[256];           // Software display name
    char publisher[256];      // Publisher name
    char version[64];         // Version string
    char installDate[32];     // Installation date (YYYYMMDD)
    char installLocation[MAX_PATH];  // Installation directory
    char uninstallString[MAX_PATH];  // Uninstall command
    char displayIcon[MAX_PATH];      // Icon path
    unsigned int estimatedSize;      // Size in KB
    int is64Bit;              // 1 = 64-bit, 0 = 32-bit
} SOFTWARE_INFO, *PSOFTWARE_INFO;
#pragma pack(pop)

// Get DLL version information
// Parameters:
//   versionString - Buffer to receive version string (e.g., "1.0.0")
//   bufferSize    - Size of the buffer
// Returns: 0 on success, -1 on error
__declspec(dllexport) int __stdcall GetLibraryVersion(char* versionString, int bufferSize);

// Enumerate installed software
// Parameters:
//   infoArray - Array to receive software info
//   arraySize - Input: array capacity, Output: actual count
// Returns: Number of software found, -1 on error
__declspec(dllexport) int __stdcall EnumerateInstalledSoftware(
    SOFTWARE_INFO* infoArray,
    int* arraySize
);

// Check if software is installed by name (partial match, case-insensitive)
// Parameters:
//   softwareName - Software name to search for (partial match supported)
// Returns: 1 = installed, 0 = not installed, -1 = error
__declspec(dllexport) int __stdcall IsSoftwareInstalled(const char* softwareName);


#ifdef __cplusplus
}
#endif

#endif // SOFTWARE_INFO_H
