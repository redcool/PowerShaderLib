#if !defined(SCREEN_TEXTURES_HLSL) 
#define SCREEN_TEXTURES_HLSL

#if !defined(SKIP_DEPTH)
TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
#endif
#if !defined(SKIP_OPAQUE)
TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);
#endif

float GetScreenDepth(float2 suv){
    float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,(suv)).x;

    #if !defined(UNITY_REVERSED_Z)
        depth = depth *2-1;
    #endif
    return depth;
}

float3 CalcWorldNormal(float3 worldPos){
    return normalize(cross(ddy(worldPos),ddx(worldPos)));
}

float3 GetScreenColor(float2 suv){
    return  SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, (suv)).xyz;
}

#endif //SCREEN_TEXTURES_HLSL