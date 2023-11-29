#if !defined(URP_GI_HLSL)
#define URP_GI_HLSL
#include "../Lib/GILib.hlsl"
//-----------------------------------------------------------EntityLight
#define LIGHTMAP_RGBM_MAX_GAMMA     float(5.0)       // NB: Must match value in RGBMRanges.h
#define LIGHTMAP_RGBM_MAX_LINEAR    float(34.493242) // LIGHTMAP_RGBM_MAX_GAMMA ^ 2.2

#ifdef UNITY_LIGHTMAP_RGBM_ENCODING
    #ifdef UNITY_COLORSPACE_GAMMA
        #define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_GAMMA
        #define LIGHTMAP_HDR_EXPONENT   float(1.0)   // Not used in gamma color space
    #else
        #define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_LINEAR
        #define LIGHTMAP_HDR_EXPONENT   float(2.2)
    #endif
#elif defined(UNITY_LIGHTMAP_DLDR_ENCODING)
    #ifdef UNITY_COLORSPACE_GAMMA
        #define LIGHTMAP_HDR_MULTIPLIER float(2.0)
    #else
        #define LIGHTMAP_HDR_MULTIPLIER float(4.59) // 2.0 ^ 2.2
    #endif
    #define LIGHTMAP_HDR_EXPONENT float(0.0)
#else // (UNITY_LIGHTMAP_FULL_HDR)
    #define LIGHTMAP_HDR_MULTIPLIER float(1.0)
    #define LIGHTMAP_HDR_EXPONENT float(1.0)
#endif


float3 UnpackLightmapRGBM(float4 rgbmInput, float4 decodeInstructions)
{
#ifdef UNITY_COLORSPACE_GAMMA
    return rgbmInput.rgb * (rgbmInput.a * decodeInstructions.x);
#else
    return rgbmInput.rgb * (PositivePow(rgbmInput.a, decodeInstructions.y) * decodeInstructions.x);

    // optimise 
    float scale = rgbmInput.w;
    #if defined(UNITY_LIGHTMAP_RGBM_ENCODING)
        scale = scale * scale;
    #endif

    return rgbmInput.rgb * ( scale * decodeInstructions.x);
#endif
}

float3 UnpackLightmapDoubleLDR(float4 encodedColor, float4 decodeInstructions)
{
    return encodedColor.rgb * decodeInstructions.x;
}

#ifndef BUILTIN_TARGET_API
float3 DecodeLightmap(float4 encodedIlluminance, float4 decodeInstructions)
{
#if defined(UNITY_LIGHTMAP_RGBM_ENCODING)
    return UnpackLightmapRGBM(encodedIlluminance, decodeInstructions);
#elif defined(UNITY_LIGHTMAP_DLDR_ENCODING)
    return UnpackLightmapDoubleLDR(encodedIlluminance, decodeInstructions);
#else // (UNITY_LIGHTMAP_FULL_HDR)
    return encodedIlluminance.rgb;
#endif
}
#endif

float3 SampleLightmap(float2 uv){
    #ifdef UNITY_LIGHTMAP_FULL_HDR
    bool encodedLightmap = false;
#else
    bool encodedLightmap = true;
#endif

    float4 decodeInstructions = float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
    float4 illum = SAMPLE_TEXTURE2D(unity_Lightmap,samplerunity_Lightmap,uv);
    return DecodeLightmap(illum,decodeInstructions);
}

float4 SampleShadowMask(float2 uv){
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    return SAMPLE_TEXTURE2D(unity_ShadowMask,samplerunity_ShadowMask,uv);
    #elif !defined(LIGHTMAP_ON)
    return unity_ProbesOcclusion;
    #else
    return 1;
    #endif
}
// not need use, keep it
half4 CalcShadowMask(half4 shadowMask)
{
    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    return shadowMask;
    #elif !defined (LIGHTMAP_ON)
    return unity_ProbesOcclusion;
    #else
    return 1;
    #endif
}
 
//--------------------- IBL

// float3 BoxProjectedCubemapDirection(float3 reflectionWS, float3 positionWS, float4 cubemapPositionWS, float4 boxMin, float4 boxMax)
// {
//     // Is this probe using box projection?
//     if (cubemapPositionWS.w > 0.0f)
//     {
//         float3 boxMinMax = (reflectionWS > 0.0f) ? boxMax.xyz : boxMin.xyz;
//         float3 rbMinMax = float3(boxMinMax - positionWS) / reflectionWS;

//         float fa = float(min(min(rbMinMax.x, rbMinMax.y), rbMinMax.z));

//         float3 worldPos = float3(positionWS - cubemapPositionWS.xyz);

//         float3 result = worldPos + reflectionWS * fa;
//         return result;
//     }
//     else
//     {
//         return reflectionWS;
//     }
// }

float CalculateProbeWeight(float3 positionWS, float4 probeBoxMin, float4 probeBoxMax)
{
    float blendDistance = probeBoxMax.w;
    float3 weightDir = min(positionWS - probeBoxMin.xyz, probeBoxMax.xyz - positionWS) / blendDistance;
    return saturate(min(weightDir.x, min(weightDir.y, weightDir.z)));
}

float CalculateProbeVolumeSqrMagnitude(float4 probeBoxMin, float4 probeBoxMax)
{
    float3 maxToMin = float3(probeBoxMax.xyz - probeBoxMin.xyz);
    return dot(maxToMin, maxToMin);
}

#undef PerceptualRoughnessToMipmapLevel
#define PerceptualRoughnessToMipmapLevel(roughness) roughness * (1.7 - roughness * 0.7) * 6
float3 CalculateIrradianceFromReflectionProbes(float3 reflectVector, float3 positionWS, float perceptualRoughness)
{
    float probe0Volume = CalculateProbeVolumeSqrMagnitude(unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
    float probe1Volume = CalculateProbeVolumeSqrMagnitude(unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);

    float volumeDiff = probe0Volume - probe1Volume;
    float importanceSign = unity_SpecCube1_BoxMin.w;

    // A probe is dominant if its importance is higher
    // Or have equal importance but smaller volume
    bool probe0Dominant = importanceSign > 0.0f || (importanceSign == 0.0f && volumeDiff < -0.0001h);
    bool probe1Dominant = importanceSign < 0.0f || (importanceSign == 0.0f && volumeDiff > 0.0001h);

    float desiredWeightProbe0 = CalculateProbeWeight(positionWS, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
    float desiredWeightProbe1 = CalculateProbeWeight(positionWS, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);

    // Subject the probes weight if the other probe is dominant
    float weightProbe0 = probe1Dominant ? min(desiredWeightProbe0, 1.0f - desiredWeightProbe1) : desiredWeightProbe0;
    float weightProbe1 = probe0Dominant ? min(desiredWeightProbe1, 1.0f - desiredWeightProbe0) : desiredWeightProbe1;

    float totalWeight = weightProbe0 + weightProbe1;

    // If either probe 0 or probe 1 is dominant the sum of weights is guaranteed to be 1.
    // If neither is dominant this is not guaranteed - only normalize weights if totalweight exceeds 1.
    weightProbe0 /= max(totalWeight, 1.0f);
    weightProbe1 /= max(totalWeight, 1.0f);

    float3 irradiance = float3(0.0h, 0.0h, 0.0h);
    float3 originalReflectVector = reflectVector;
    float mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);

    // Sample the first reflection probe
    if (weightProbe0 > 0.01f)
    {
#ifdef _REFLECTION_PROBE_BOX_PROJECTION
        reflectVector = BoxProjectedCubemapDirection(originalReflectVector, positionWS, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
#endif // _REFLECTION_PROBE_BOX_PROJECTION

        float4 encodedIrradiance = float4(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip));

#if defined(UNITY_USE_NATIVE_HDR)
        irradiance += weightProbe0 * encodedIrradiance.rbg;
#else
        irradiance += weightProbe0 * DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
#endif // UNITY_USE_NATIVE_HDR
    }

    // Sample the second reflection probe
    if (weightProbe1 > 0.01f)
    {
#ifdef _REFLECTION_PROBE_BOX_PROJECTION
        reflectVector = BoxProjectedCubemapDirection(originalReflectVector, positionWS, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
#endif // _REFLECTION_PROBE_BOX_PROJECTION
        float4 encodedIrradiance = float4(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube1, samplerunity_SpecCube1, reflectVector, mip));

#if defined(UNITY_USE_NATIVE_HDR) || defined(UNITY_DOTS_INSTANCING_ENABLED)
        irradiance += weightProbe1 * encodedIrradiance.rbg;
#else
        irradiance += weightProbe1 * DecodeHDREnvironment(encodedIrradiance, unity_SpecCube1_HDR);
#endif // UNITY_USE_NATIVE_HDR || UNITY_DOTS_INSTANCING_ENABLED
    }

    // Use any remaining weight to blend to environment reflection cube map
    if (totalWeight < 0.99f)
    {
        float4 encodedIrradiance = float4(SAMPLE_TEXTURECUBE_LOD(_GlossyEnvironmentCubeMap, sampler_GlossyEnvironmentCubeMap, originalReflectVector, mip));

#if defined(UNITY_USE_NATIVE_HDR) || defined(UNITY_DOTS_INSTANCING_ENABLED)
        irradiance += (1.0f - totalWeight) * encodedIrradiance.rbg;
#else
        irradiance += (1.0f - totalWeight) * DecodeHDREnvironment(encodedIrradiance, _GlossyEnvironmentCubeMap_HDR);
#endif // UNITY_USE_NATIVE_HDR || UNITY_DOTS_INSTANCING_ENABLED
    }

    return irradiance;
}

float3 GlossyEnvironmentReflection(float3 reflectVector, float3 positionWS, float perceptualRoughness, float occlusion)
{
#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    float3 irradiance;

#ifdef _REFLECTION_PROBE_BLENDING
    irradiance = CalculateIrradianceFromReflectionProbes(reflectVector, positionWS, perceptualRoughness);
    return irradiance;
#else
#ifdef _REFLECTION_PROBE_BOX_PROJECTION
    reflectVector = BoxProjectedCubemapDirection(reflectVector, positionWS, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
#endif // _REFLECTION_PROBE_BOX_PROJECTION
    float mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    float4 encodedIrradiance = float4(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip));

#if defined(UNITY_USE_NATIVE_HDR)
    irradiance = encodedIrradiance.rgb;
#else
    irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
#endif // UNITY_USE_NATIVE_HDR
#endif // _REFLECTION_PROBE_BLENDING
    return irradiance * occlusion;
#else
    return _GlossyEnvironmentColor.rgb * occlusion;
#endif // _ENVIRONMENTREFLECTIONS_OFF
}

#endif // URP_GI_HLSL