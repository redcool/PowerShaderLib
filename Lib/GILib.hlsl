#if !defined(GI_LIB_HLSL)
#define GI_LIB_HLSL

#include "../Lib/ReflectionLib.hlsl"

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