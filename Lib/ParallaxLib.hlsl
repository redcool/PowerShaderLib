#if !defined(PARALLAX_LIB_HLSL)
#define PARALLAX_LIB_HLSL

#include "ParallaxMapping.hlsl"

TEXTURE2D(_ParallaxMap);SAMPLER(sampler_ParallaxMap);

/**
    define _PARALLAX_FULL use parallaxIterate
*/
// #define _PARALLAX_FULL

void ApplyParallax(inout float2 mainUV,float3 viewTS,float parallaxHeight,int parallaxMapChannel=3,int parallaxIterate=1,float4 tilingOffset=float4(1,1,0,0)){
    float size = 1.0/parallaxIterate;

    #if defined(_PARALLAX_FULL)
    for(int i=0;i<parallaxIterate;i++)
    #endif

    {
        float2 uv = mainUV * tilingOffset.xy + tilingOffset.zw;
        float height = SAMPLE_TEXTURE2D(_ParallaxMap,sampler_ParallaxMap,uv)[parallaxMapChannel];
        mainUV += ParallaxMapOffset(parallaxHeight,viewTS,height) * height * size;
    }
}

#endif // PARALLAX_LIB_HLSL