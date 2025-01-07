#if !defined(SCREEN_TEXTURES_HLSL) 
#define SCREEN_TEXTURES_HLSL

#include "DepthLib.hlsl"

/***
    define SKIP_DEPTH ,when use DeclareDepthTexture.hlsl
    define SKIP_OPAQUE , when use DeclareOpaqueTexture.hlsl
*/
// check urp DeclareDepthTexture.hlsl collision
#if !defined(SKIP_DEPTH)
TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
#endif

#if !defined(SKIP_OPAQUE)
TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);
#endif

float GetScreenDepth(TEXTURE2D_PARAM(tex,state),float2 screenUV){
    float depth = SAMPLE_TEXTURE2D(tex,state,screenUV).x;

    // for GL, [0,1] ->[-1,1]
    // #if !defined(UNITY_REVERSED_Z)
    //     depth = depth * 2-1;
    // #endif
    return depth;
}

float GetScreenDepth(float2 screenUV){
    return SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV).x;
}

float3 GetScreenColor(float2 screenUV){
    return SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, (screenUV)).xyz;
}

float3 CalcWorldNormal(float3 worldPos){
    return normalize(cross(ddy(worldPos),ddx(worldPos)));
}

#endif //SCREEN_TEXTURES_HLSL