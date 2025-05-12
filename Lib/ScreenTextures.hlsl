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

#if !defined(SKIP_NORMAL)
TEXTURE2D(_CameraNormalsTexture);
SAMPLER(sampler_CameraNormalsTexture);
#endif

/*
    get depth 
    gl : return [-1,1]
    others: return [1,0]
*/
float GetScreenDepth(TEXTURE2D_PARAM(tex,state),float2 screenUV){
    float depth = SAMPLE_TEXTURE2D(tex,state,screenUV).x;

    // for GL, [0,1] ->[-1,1]
    #if !defined(UNITY_REVERSED_Z)
        depth = depth * 2-1;
    #endif
    return depth;
}
/**
    get rawDepth
*/
float GetScreenDepth(float2 screenUV){
    return SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV).x;
}

float4 GetScreenColor(float2 screenUV){
    return SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, (screenUV));
}

float3 CalcWorldNormal(float3 worldPos){
    return normalize(cross(ddy(worldPos),ddx(worldPos)));
}

float3 GetScreenNormal(float2 screenUV){
    return SAMPLE_TEXTURE2D(_CameraNormalsTexture,sampler_CameraNormalsTexture,screenUV).xyz * 2 - 1;
}

float3 ScreenToWorld(float2 suv){
    float rawDepth = GetScreenDepth(suv);
    return ScreenToWorldPos(suv,rawDepth,UNITY_MATRIX_I_VP);
}

#endif //SCREEN_TEXTURES_HLSL