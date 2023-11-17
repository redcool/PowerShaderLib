#if !defined(PARALLAX_LIB_HLSL)
#define PARALLAX_LIB_HLSL

#include "ParallaxMapping.hlsl"

TEXTURE2D(_ParallaxMap);SAMPLER(sampler_ParallaxMap);

void ApplyParallax(inout float2 uv,float3 viewTS,float parallaxHeight,int parallaxMapChannel=3,int parallaxIterate=1){
    float size = 1.0/parallaxIterate;
    for(int i=0;i<parallaxIterate;i++)
    {
        float height = SAMPLE_TEXTURE2D(_ParallaxMap,sampler_ParallaxMap,uv)[parallaxMapChannel];
        uv += ParallaxMapOffset(parallaxHeight,viewTS,height) * height * size;
    }
}

#endif // PARALLAX_LIB_HLSL