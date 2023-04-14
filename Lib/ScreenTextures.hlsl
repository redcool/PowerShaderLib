#if !defined(SCREEN_TEXTURES_HLSL)
#define SCREEN_TEXTURES_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

float GetScreenDepth(float2 suv){
    float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(suv)).x;

    #if !defined(UNITY_REVERSED_Z)
        depth = depth *2-1;
    #endif
    return depth;
}

float3 CalcWorldNormal(float3 worldPos){
    return normalize(cross(ddy(worldPos),ddx(worldPos)));
}

float3 GetScreenColor(float2 suv){
    return  SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, UnityStereoTransformScreenSpaceTex(suv)).xyz;
}

#endif //SCREEN_TEXTURES_HLSL