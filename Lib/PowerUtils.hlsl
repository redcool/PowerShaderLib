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

/**
    screenPos : i.vertex.xy,[0,screenWidth,screenHeight]
    pixels : a block size
*/
void ClipLOD(float2 screenPos,float pixels=1){
    // #if defined(LOD_FADE_CROSSFADE)
    screenPos = floor(screenPos/pixels);
    float fade = unity_LODFade.x;

    // float dither = screenPos.y % 16/16;
    float dither = InterleavedGradientNoise(screenPos.xy,0);
    dither *= lerp(-1,1,fade < 0);
    clip(fade + dither);
    // #endif
}


#endif //POWER_UTILS_HLSL