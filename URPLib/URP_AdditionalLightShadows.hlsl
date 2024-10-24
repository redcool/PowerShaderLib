/*
    need keywords:
    _ADDITIONAL_LIGHT_SHADOWS
    _ADDITIONAL_LIGHT_SHADOWS_SOFT 
*/

#if !defined(URP_ADDITIONAL_LIGHT_SHADOWS_HLSL)
#define URP_ADDITIONAL_LIGHT_SHADOWS_HLSL
#include "URP_MainLightShadows.hlsl"

TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture);SAMPLER_CMP(sampler_AdditionalLightsShadowmapTexture);

#ifndef SHADER_API_GLES3
CBUFFER_START(AddtionalLightShadows)
#endif

float4      _AdditionalShadowOffset0; // xy: offset0, zw: offset1
float4      _AdditionalShadowOffset1; // xy: offset2, zw: offset3
float4      _AdditionalShadowFadeParams; // x: additional light fade scale, y: additional light fade bias, z: 0.0, w: 0.0)
float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)

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

// #if defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
    #if !USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    // Point lights can use 6 shadow slices. Some mobile GPUs performance decrease drastically with uniform
    // blocks bigger than 8kb while others have a 64kb max uniform block size. This number ensures size of buffer
    // AdditionalLightShadows stays reasonable. It also avoids shader compilation errors on SHADER_API_GLES30
    // devices where max number of uniforms per shader GL_MAX_FRAGMENT_UNIFORM_VECTORS is low (224)
    float4      _AdditionalShadowParams[MAX_VISIBLE_LIGHTS];         // Per-light data
    float4x4    _AdditionalLightsWorldToShadow[MAX_VISIBLE_LIGHTS];  // Per-shadow-slice-data
    #endif
// #endif

#ifndef SHADER_API_GLES3
CBUFFER_END
#endif

struct ShadowSamplingData
{
    float4 shadowOffset0;
    float4 shadowOffset1;
    // unity 2022+, deprecated
    // float4 shadowOffset2;
    // float4 shadowOffset3;
    float4 shadowmapSize;
    half softShadowQuality;
};

ShadowSamplingData GetAdditionalLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData = (ShadowSamplingData)0;

    // shadowOffsets are used in SampleShadowmapFiltered #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
    shadowSamplingData.shadowOffset0 = _AdditionalShadowOffset0;
    shadowSamplingData.shadowOffset1 = _AdditionalShadowOffset1;
    // shadowSamplingData.shadowOffset2 = _AdditionalShadowOffset2;
    // shadowSamplingData.shadowOffset3 = _AdditionalShadowOffset3;

    // shadowmapSize is used in SampleShadowmapFiltered for other platforms
    shadowSamplingData.shadowmapSize = _AdditionalShadowmapSize;

    return shadowSamplingData;
}

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
// z: 1.0 if cast by a point light (6 shadow slices), 0.0 if cast by a spot light (1 shadow slice)
// w: first shadow slice index for this light, there can be 6 in case of point lights. (-1 for non-shadow-casting-lights)
float4 GetAdditionalLightShadowParams(int lightIndex)
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    return _AdditionalShadowParams_SSBO[lightIndex];
#else
    return _AdditionalShadowParams[lightIndex];
#endif
}

float SampleShadowmapFiltered(ShadowSamplingData samplingData,float4 shadowCoord,float softScale=1){
    float4 atten4 = 0;
    atten4.x = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + float3(samplingData.shadowOffset0.xy,0) * softScale);
    atten4.y = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + float3(samplingData.shadowOffset0.zw,0) * softScale);
    atten4.z = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + float3(samplingData.shadowOffset1.xy,0) * softScale);
    atten4.w = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz + float3(samplingData.shadowOffset1.zw,0) * softScale);
    return dot(atten4,0.25);
}

// returns 0.0 if position is in light's shadow
// returns 1.0 if position is in light
float AdditionalLightRealtimeShadow(int lightIndex, float3 positionWS,float softScale=1,float3 lightDirection=0)
{
    float4 shadowParams = GetAdditionalLightShadowParams(lightIndex);
    float shadowStrength = shadowParams.x;
    half isPoint = shadowParams.z;
    int shadowSliceIndex = shadowParams.w;

    if(shadowSliceIndex < 0)
        return 1;

    UNITY_BRANCH
    if(isPoint)
    {
        float cubemapFaceId = CubeMapFaceID(-lightDirection);
        shadowSliceIndex += cubemapFaceId;
    }

    #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
        float4 shadowCoord = mul(_AdditionalLightsWorldToShadow_SSBO[shadowSliceIndex], float4(positionWS, 1.0));
    #else
        float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[shadowSliceIndex], float4(positionWS, 1.0));
    #endif

    // perspective 
    shadowCoord.xyz /= shadowCoord.w;

    float attenuation = 1;
    #if defined(_ADDITIONAL_LIGHT_SHADOWS_SOFT)
        ShadowSamplingData samplingData = GetAdditionalLightShadowSamplingData();
        samplingData.softShadowQuality = shadowParams.y; //dont need yet
        attenuation = SampleShadowmapFiltered(samplingData,shadowCoord,softScale);
    #else
    // 1-tap hardware comparison
        attenuation = SAMPLE_TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture,sampler_AdditionalLightsShadowmapTexture, shadowCoord.xyz);
    #endif

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

float AdditionalLightShadow(int lightIndex, float3 positionWS,float4 shadowMask,float4 occlusionProbeChannels,float softScale=1,float3 lightDirection=0)
{
    float realtimeShadow = AdditionalLightRealtimeShadow(lightIndex, positionWS,softScale,lightDirection);
    return realtimeShadow;
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