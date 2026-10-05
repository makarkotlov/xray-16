#include "TestSupport.h"

#include <cmath>
#include <limits>

void CheckRayEndpoints()
{
    // Embree rounds this intersection farther away than X-Ray's triangle test.
    // An axis-aligned fixture does not expose that candidate-pruning difference.
    const auto start = Vector(11.5479259f, -0.446451187f, 6.58045769f);
    const auto direction = Vector(-0.842234433f, -0.163424194f, -0.513744771f);
    for (const bool cull : { false, true })
    {
        Fvector vertices[] = {
            Vector(16.0451088f, -16.2396832f, -2.19739532f),
            Vector(-14.2716551f, 14.8169899f, 1.34327698f),
            Vector(-10.002039f, -8.23546219f, -5.55572319f)
        };

        Mesh mesh;
        mesh.Add(vertices[0], vertices[1], vertices[2]);
        mesh.Add(vertices[0], vertices[1], vertices[2]);
        CDB::MODEL model;
        mesh.Build(model);

        float u, v, distance;
        Require(CDB::TestRayTri(start, direction, vertices, u, v, distance, cull) && distance > 0,
            "Endpoint fixture must intersect the triangle");
        const float before = std::nextafter(distance, 0.f);
        const float after = std::nextafter(distance, std::numeric_limits<float>::infinity());
        CDB::COLLIDER collider;
        for (const u32 selection : { 0u, u32(CDB::OPT_ONLYFIRST), u32(CDB::OPT_ONLYNEAREST),
            u32(CDB::OPT_ONLYFIRST | CDB::OPT_ONLYNEAREST) })
        {
            const u32 mode = selection | (cull ? u32(CDB::OPT_CULL) : 0u);
            const u32 expectedCount = selection ? 1u : 2u;
            for (const float range : { distance, after })
            {
                collider.ray_query(mode, &model, start, direction, range);
                Require(Ids(collider, mesh).size() == expectedCount,
                    "Ray lost a hit at or inside its inclusive endpoint");
                for (const auto& hit : *collider.r_get())
                    Require(hit.range == distance, "Ray endpoint distance changed");
            }
            collider.ray_query(mode, &model, start, direction, before);
            Require(collider.r_count() == 0, "Ray accepted a hit beyond its requested range");
        }
    }
}
