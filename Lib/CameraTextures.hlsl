#if !defined(CAMERA_TEXTURES_HLSL)
#define CAMERA_TEXTURES_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

float SampleCameraDepthTexture(float2 suv){
    float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,UnityStereoTransformScreenSpaceTex(suv)).x;

    #if !defined(UNITY_REVERSED_Z)
        depth = depth *2-1;
    #endif
    return depth;
}

float3 SampleCameraOpaqueTexture(float2 suv){
    return  SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, UnityStereoTransformScreenSpaceTex(suv)).xyz;
}

#endif //CAMERA_TEXTURES_HLSL