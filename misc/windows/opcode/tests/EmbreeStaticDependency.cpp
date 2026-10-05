#include <embree4/rtcore.h>

int CheckEmbreeStaticDependency()
{
    RTCDevice device = rtcNewDevice("threads=1");
    if (!device)
        return 1;
    const RTCError error = rtcGetDeviceError(device);
    rtcReleaseDevice(device);
    return error == RTC_ERROR_NONE ? 0 : 2;
}
