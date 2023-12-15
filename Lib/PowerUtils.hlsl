#if !defined(POWER_UTILS_HLSL)
#define POWER_UTILS_HLSL
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "DepthLib.hlsl"


#if defined(URP_LEGACY_HLSL)
    #define texCUBElod(cube,coord) cube.SampleLevel(sampler##cube,coord.xyz,coord.w)
#endif //URP_LEGACY_HLSL

// #define GetWorldSpaceViewDir(worldPos) (_WorldSpaceCameraPos - worldPos)
// #define GetWorldSpaceLightDir(worldPos) _MainLightPosition.xyz

/**
    blend vertex normal and tangent noraml(texture)
*/
float3 BlendVertexNormal(float3 tn,float3 worldPos,float3 t,float3 b,float3 n){
    float3 vn = cross(ddy(worldPos),ddx(worldPos));
    vn = float3(dot(t,vn),dot(b,vn),dot(n,vn));
    return BlendNormal(tn,vn);
}




#endif //POWER_UTILS_HLSL