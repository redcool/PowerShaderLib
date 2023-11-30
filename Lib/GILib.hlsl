#if !defined(GI_LIB_HLSL)
#define GI_LIB_HLSL
/**
    GIDiff(sh,lightmap),
    GISpec(ibl)

    _INTERIOR_MAP_ON
    _PLANAR_REFLECTION_ON
    LIGHTMAP_ON
    SMOOTH_FRESNEL //smooth pow(1-nv,4)

    can override
    unity_Lightmap samplerunity_Lightmap
    unity_ShadowMask samplerunity_ShadowMask

*/
#include "../Lib/ReflectionLib.hlsl"

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


float3 CalcGIDiff(float3 normal,float3 diffColor,float2 lightmapUV=0){
    float3 giDiff = 0;
    #if defined(LIGHTMAP_ON)
        giDiff = SampleLightmap(lightmapUV) * diffColor;
    #else
        giDiff = SampleSH(normal) * diffColor;
    #endif
    return giDiff;
}


/**
    #define SMOOTH_FRESNEL, adjust fresnel curve
*/
float CalcFresnelTerm(float nv,half2 fresnelRange=half2(0,1)){
    float fresnelTerm = Pow4(1 - nv);
    #if defined(SMOOTH_FRESNEL)
    fresnelTerm = smoothstep(fresnelRange.x,fresnelRange.y,fresnelTerm);
    #endif
    return fresnelTerm;
}

//--------------------- IBL
float3 DecodeHDREnvironment(float4 encodedIrradiance, float4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    float alpha = max(decodeInstructions.w * (encodedIrradiance.a - 1.0) + 1.0, 0.0);

    // If Linear mode is not supported we can skip exponent part
    return (decodeInstructions.x * PositivePow(alpha, decodeInstructions.y)) * encodedIrradiance.rgb;
}
#define DecodeHDR(encodedIrradiance,decodeInstructions) DecodeHDREnvironment(encodedIrradiance,decodeInstructions) 

float3 CalcIBL(float3 reflectDir,TEXTURECUBE_PARAM(cube,sampler_cube),float rough,float4 hdrEncode){
    float mip = (1.7 - 0.7*rough)*6*rough;
    float4 cubeColor = SAMPLE_TEXTURECUBE_LOD(cube,sampler_cube,reflectDir,mip);
    #if defined(UNITY_USE_NATIVE_HDR) || defined(UNITY_DOTS_INSTANTING_ENABLED)
        float3 iblColor = cubeColor.rgb;
    #else // mobile
        float3 iblColor = DecodeHDREnvironment(cubeColor,hdrEncode);//_IBLCube_HDR,unity_SpecCube0_HDR
    #endif
    return iblColor;
}

half3 CalcGISpec(float a2,float smoothness,float metallic,float fresnelTerm,half3 specColor,half3 iblColor,half3 grazingTermColor=1){
    float surfaceReduction = 1/(a2+1);
    // float oneMinusReflective = (0.96 - metallic * 0.96);
    // float reflective = 1 - oneMinusReflective;
    float reflective = metallic *0.96 + 0.04;
    
    float grazingTerm = saturate(smoothness + reflective);
    float3 giSpec = iblColor * surfaceReduction * lerp(specColor,grazingTermColor * grazingTerm,fresnelTerm);
    return giSpec;
}

/**
    _PLANAR_REFLECTION_ON, if use planar reflection
    _INTERIOR_MAP_ON ,use interior map
*/

half3 CalcGISpec(TEXTURECUBE_PARAM(cube,sampler_cube),float4 cubeHDR,float3 specColor,
    float3 worldPos,float3 normal,float3 viewDir,float3 reflectDirOffset,float reflectIntensity,
    float nv,float roughness,float a2,float smoothness,float metallic,half2 fresnelRange=half2(0,1),half3 grazingTermColor=1,
    // planar reflection tex,(xyz:color,w: ratio)
    half4 planarReflectTex=0,half3 viewDirTS=0,half2 uv=0)
{
    #if defined(_INTERIOR_MAP_ON)
        float2 uvRange = float2(_ReflectDirOffset.w,1 - _ReflectDirOffset.w);
        float3 reflectDir = CalcInteriorMapReflectDir(viewDirTS,uv,uvRange);
        roughness = lerp(0.5,roughness,UVBorder(uv,uvRange));
        // reflectDir.z*=-1;
    #else
        float3 reflectDir = CalcReflectDir(worldPos,normal,viewDir,reflectDirOffset);
    #endif

    float3 iblColor = CalcIBL(reflectDir,cube,sampler_cube,roughness,cubeHDR) * reflectIntensity;

    #if defined(_PLANAR_REFLECTION_ON)
        // blend planar reflection texture
        iblColor = lerp(iblColor,planarReflectTex.xyz,planarReflectTex.w);
    #endif
    
    float fresnelTerm = CalcFresnelTerm(nv,fresnelRange);
    float3 giSpec = CalcGISpec(a2,smoothness,metallic,fresnelTerm,specColor,iblColor,grazingTermColor);
    return giSpec;
}

#endif //GI_LIB_HLSL