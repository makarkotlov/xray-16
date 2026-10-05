# Collision regression checks

Enable `XRAY_BUILD_CDB_TESTS` to build the collision/cache checks. With
`XRAY_COLLISION_EMBREE=ON`, CTest runs both synchronous and `-mt_cdb` cases for
each of the `opcode`, `hybrid`, and `embree` routing policies. Each case sets its
own environment and uses a separate directory, so `ctest --parallel` is safe.
Without Embree, only the two OPCODE cases are registered.

`RayEndpoints.cpp` exercises a non-axis-aligned triangle for which Embree and
X-Ray round the intersection distance differently. It checks the exact endpoint
and adjacent floating-point ranges, with and without culling, for all-hit,
first-hit, nearest-hit, and combined selection flags. Padding candidate traversal
must not admit a hit beyond the caller's exact range.

On MSVC with Embree enabled, `xrCDB.embree_master_gold_link` also tests native
Master Gold library dependencies. It imports the actual `xrCDB.vcxproj` settings,
builds a small archive containing RTC calls, then links and runs a consumer
without directly linking Embree. This checks dependency propagation through the
native librarian; it does not build the entire Master Gold engine.

## Windows component build

The component project requires matching native engine libraries/DLLs, restored
SDL NuGet packages, and an OPCODE 1.3 import-library/DLL pair. Set paths to your
existing builds and Embree SDK:

```powershell
cmake -S misc/windows/opcode -B build/opcode-checks -A x64 `
  -DXRAY_NATIVE_BUILD_ROOT=C:/path/to/native-checkout `
  -DXRAY_OPCODE13_IMPLIB=C:/path/to/opcode/OPCODE.lib `
  -DXRAY_OPCODE13_DLL=C:/path/to/opcode/OPCODE.dll `
  -DXRAY_COLLISION_EMBREE=ON `
  -DXRAY_EMBREE_ROOT=C:/path/to/embree-sdk
cmake --build build/opcode-checks --config Release --parallel
```

Add the native runtime, OPCODE runtime, and Embree SDK `bin` directories to
`PATH`, then run:

```powershell
ctest --test-dir build/opcode-checks -C Release --output-on-failure --parallel
```

The native link check needs MSVC x64 and the Windows SDK. It uses the Visual
Studio generator's MSBuild executable, or discovers Visual Studio 2022 when
another generator is used. Its standalone driver accepts `XRAY_SOURCE_DIR`,
`XRAY_EMBREE_ROOT`, `TEST_OUTPUT_DIR`, and an optional `XRAY_MSBUILD` path via
`cmake -D... -P misc/windows/opcode/tests/CheckEmbreeStaticLink.cmake`.
