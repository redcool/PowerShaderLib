#if !defined(URP_ADDITIONAL_LIGHT_SHADOWS_HLSL)
#define URP_ADDITIONAL_LIGHT_SHADOWS_HLSL
#include "URP_MainLightShadows.hlsl"
#define MAX_SHADOW_CASCADES 4

TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture);SAMPLER_CMP(sampler_AdditionalLightsShadowmapTexture);

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA

StructuredBuffer<float4>   _AdditionalShadowParams_SSBO;        // Per-light data - TODO: test if splitting _AdditionalShadowParams_SSBO[lightIndex].w into a separate StructuredBuffer<int> buffer is faster
StructuredBuffer<half4x4> _AdditionalLightsWorldToShadow_SSBO; // Per-shadow-slice-data - A shadow casting light can have 6 shadow slices (if it's a point light)

float4       _AdditionalShadowOffset0;
float4       _AdditionalShadowOffset1;
float4       _AdditionalShadowOffset2;
float4       _AdditionalShadowOffset3;
float4       _AdditionalShadowFadeParams; // x: additional light fade scale, y: additional light fade bias, z: 0.0, w: 0.0)
float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
#else


#if defined(SHADER_API_MOBILE) || (defined(SHADER_API_GLCORE) && !defined(SHADER_API_SWITCH)) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) // Workaround for bug on Nintendo Switch where SHADER_API_GLCORE is mistakenly defined
// Point lights can use 6 shadow slices, but on some mobile GPUs performance decrease drastically with uniform blocks bigger than 8kb. This number ensures size of buffer AdditionalLightShadows stays reasonable.
// It also avoids shader compilation errors on SHADER_API_GLES30 devices where max number of uniforms per shader GL_MAX_FRAGMENT_UNIFORM_VECTORS is low (224)
// Keep in sync with MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO in AdditionalLightsShadowCasterPass.cs
#define MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO (MAX_VISIBLE_LIGHTS)
#else
// Point lights can use 6 shadow slices, but on some platforms max uniform block size is 64kb. This number ensures size of buffer AdditionalLightShadows does not exceed this 64kb limit.
// Keep in sync with MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO in AdditionalLightsShadowCasterPass.cs
#define MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO 545
#endif

// GLES3 causes a performance regression in some devices when using CBUFFER.
#ifndef SHADER_API_GLES3
CBUFFER_START(AdditionalLightShadows)
#endif

float4       _AdditionalShadowParams[MAX_VISIBLE_LIGHTS];                              // Per-light data
half4x4    _AdditionalLightsWorldToShadow[MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO];  // Per-shadow-slice-data

float4       _AdditionalShadowOffset0;
float4       _AdditionalShadowOffset1;
float4       _AdditionalShadowOffset2;
float4       _AdditionalShadowOffset3;
float4       _AdditionalShadowFadeParams; // x: additional light fade scale, y: additional light fade bias, z: 0.0, w: 0.0)
float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)

#ifndef SHADER_API_GLES3
CBUFFER_END
#endif

#endif

#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0

struct ShadowSamplingData
{
    float4 shadowOffset0;
    float4 shadowOffset1;
    float4 shadowOffset2;
    float4 shadowOffset3;
    float4 shadowmapSize;
};

ShadowSamplingData GetAdditionalLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData;

    // shadowOffsets are used in SampleShadowmapFiltered #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
    shadowSamplingData.shadowOffset0 = _AdditionalShadowOffset0;
    shadowSamplingData.shadowOffset1 = _AdditionalShadowOffset1;
    shadowSamplingData.shadowOffset2 = _AdditionalShadowOffset2;
    shadowSamplingData.shadowOffset3 = _AdditionalShadowOffset3;

    // shadowmapSize is used in SampleShadowmapFiltered for other platforms
    shadowSamplingData.shadowmapSize = _AdditionalShadowmapSize;

    return shadowSamplingData;
}

float4 GetAdditionalLightShadowParams(int lightIndex)
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    return _AdditionalShadowParams_SSBO[lightIndex];
#else
    return _AdditionalShadowParams[lightIndex];
#endif
}

float SampleShadowmapFiltered(ShadowSamplingData samplingData,float4 shadowCoord){
    float4 atten4 = 0;
    atten4.x = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + samplingData.shadowOffset0.xyz);
    atten4.y = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + samplingData.shadowOffset1.xyz);
    atten4.z = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + samplingData.shadowOffset2.xyz);
    atten4.w = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + samplingData.shadowOffset3.xyz);
    return dot(atten4,0.25);
}

// returns 0.0 if position is in light's shadow
// returns 1.0 if position is in light
float AdditionalLightRealtimeShadow(int lightIndex, float3 positionWS,bool isSoftShadow)
{
    float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[lightIndex], float4(positionWS, 1.0));
    // perspective 
    shadowCoord.xyz /= shadowCoord.w;

    float4 shadowParams = GetAdditionalLightShadowParams(lightIndex);
    float shadowStrength = shadowParams.x;

    float attenuation = 1;
    if(isSoftShadow){
        ShadowSamplingData samplingData = GetAdditionalLightShadowSamplingData();
        attenuation = SampleShadowmapFiltered(samplingData,shadowCoord);
    }else{
    // 1-tap hardware comparison
        attenuation = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz);
    }

    // attenuation = LerpWhiteTo(attenuation, shadowStrength);
    attenuation = lerp(1,attenuation,shadowStrength);
    return BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;
}

float GetAdditionalLightShadowFade(float3 positionWS)
{
    float3 camToPixel = positionWS - _WorldSpaceCameraPos;
    float distanceCamToPixel2 = dot(camToPixel, camToPixel);

    float fade = saturate(distanceCamToPixel2 * float(_AdditionalShadowFadeParams.x) + float(_AdditionalShadowFadeParams.y));
    return float(fade);
}

float AdditionalLightShadow(int lightIndex, float3 positionWS, bool isSoftShadow,float4 shadowMask,float4 occlusionProbeChannels)
{
    float realtimeShadow = AdditionalLightRealtimeShadow(lightIndex, positionWS, isSoftShadow);
    
    #ifdef CALCULATE_BAKED_SHADOWS
        float bakedShadow = BakedShadow(shadowMask, occlusionProbeChannels);
    #else
        float bakedShadow = float(1.0);
    #endif

    #ifdef ADDITIONAL_LIGHT_CALCULATE_SHADOWS
        float shadowFade = GetAdditionalLightShadowFade(positionWS);
    #else
        float shadowFade = float(1.0);
    #endif

    return MixRealtimeAndBakedShadows(realtimeShadow, bakedShadow, shadowFade);
}

#endif //URP_ADDITIONAL_LIGHT_SHADOWS_HLSL