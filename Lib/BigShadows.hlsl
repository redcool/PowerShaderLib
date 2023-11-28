#if !defined(BIG_SHADOWS_HLSL)
#define BIG_SHADOWS_HLSL
#include "UnityLib.hlsl"

#define _MainLightShadowmapSize _BigShadowMap_TexelSize
#include "ShadowsLib.hlsl"

#define SHADOW_INTENSITY _BigShadowParams.x

TEXTURE2D(_BigShadowMap); SAMPLER_CMP(sampler_BigShadowMap);
float4x4 _BigShadowMap_TexelSize;
float4x4 _BigShadowVP;
float4 _BigShadowParams; //{x: shadow intensity}

float3 TransformWorldToBigShadow(float3 worldPos){
    float3 bigShadowCoord = mul(_BigShadowVP,float4(worldPos,1)).xyz;
    return bigShadowCoord;
}

/**
    _SHADOWS_SOFT for soft shadow 
*/
float CalcBigShadowAtten(float3 bigShadowCoord,float softScale){
    float shadow = SampleShadowmap(_BigShadowMap,sampler_BigShadowMap,bigShadowCoord.xyzx,softScale);
    shadow = lerp(1,shadow,SHADOW_INTENSITY);
    
    if(any(bigShadowCoord <= 0) || any(bigShadowCoord >= 1))
        shadow = 1;
    
    return shadow;
}

#endif // BIG_SHADOWS_HLSL