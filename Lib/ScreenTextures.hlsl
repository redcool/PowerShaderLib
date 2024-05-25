#if !defined(SCREEN_TEXTURES_HLSL) 
#define SCREEN_TEXTURES_HLSL

/***
    define SKIP_DEPTH ,when you wanna use DeclareDepthTexture.hlsl
    define SKIP_OPAQUE , when you wanna use DeclareOpaqueTexture.hlsl
*/
float GetScreenDepth(TEXTURE2D_PARAM(tex,state),float2 suv){
    float depth = SAMPLE_TEXTURE2D(tex,state,suv).x;
    #if !defined(UNITY_REVERSED_Z)
        depth = depth * 2-1;
    #endif
    return depth;
}

float3 CalcWorldNormal(float3 worldPos){
    return normalize(cross(ddy(worldPos),ddx(worldPos)));
}

float3 GetScreenColor(TEXTURE2D_PARAM(tex,state),float2 suv){
    return SAMPLE_TEXTURE2D(tex,state,suv).xyz;
}

// check urp DeclareDepthTexture.hlsl collision
#if !defined(SKIP_DEPTH)
TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
#endif

#if !defined(SKIP_OPAQUE)
TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);
#endif

float GetScreenDepth(float2 suv){
    return GetScreenDepth(_CameraDepthTexture,sampler_CameraDepthTexture,suv);
}

float GetRawScreenDepth(float2 suv){
    float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,suv).x;
    return depth;
}

float3 GetScreenColor(float2 suv){
    return  SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, (suv)).xyz;
}

#endif //SCREEN_TEXTURES_HLSL