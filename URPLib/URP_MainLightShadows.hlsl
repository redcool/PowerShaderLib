/**
    MainLight Shadow
    keywords

    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE //_MAIN_LIGHT_SHADOWS_SCREEN
    LIGHTMAP_ON
    _SHADOWS_SOFT 
    _ADDITIONAL_LIGHT_SHADOWS 
    _ADDITIONAL_LIGHT_SHADOWS_SOFT
    _RECEIVE_SHADOWS_ON or _RECEIVE_SHADOWS_OFF // material keyword

    // shadow(realtime,baked mixing)
    LIGHTMAP_SHADOW_MIXING , urp use this 
    SHADOWS_FULL_MIX , use this for full blend
*/
#if !defined(MAIN_LIGHT_SHADOW_HLSL)
#define MAIN_LIGHT_SHADOW_HLSL

#if !defined(MAX_SHADOW_CASCADES)
#define MAX_SHADOW_CASCADES 4
#endif

#if defined(_RECEIVE_SHADOWS_ON) || ! defined(_RECEIVE_SHADOWS_OFF)
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)
        #define MAIN_LIGHT_CALCULATE_SHADOWS

        #if defined(_MAIN_LIGHT_SHADOWS) || (defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT))
            #define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
    #endif

    #if defined(_ADDITIONAL_LIGHT_SHADOWS) || defined(_ADDITIONAL_LIGHT_SHADOWS_ON)
        #define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
    #endif
#endif

#if defined(LIGHTMAP_ON) || defined(LIGHTMAP_SHADOW_MIXING) || defined(SHADOWS_SHADOWMASK)
    #define CALCULATE_BAKED_SHADOWS
#endif

TEXTURE2D_SHADOW(_ScreenSpaceShadowmapTexture);SAMPLER(sampler_ScreenSpaceShadowmapTexture);
TEXTURE2D_SHADOW(_MainLightShadowmapTexture);SAMPLER_CMP(sampler_MainLightShadowmapTexture);

//=========== from URP Shadows.hlsl
// GLES3 causes a performance regression in some devices when using CBUFFER.
#ifndef SHADER_API_GLES3
CBUFFER_START(LightShadows)
#endif

// Last cascade is initialized with a no-op matrix. It always transforms
// shadow coord to half3(0, 0, NEAR_PLANE). We use this trick to avoid
// branching since ComputeCascadeIndex can return cascade index = MAX_SHADOW_CASCADES
float4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
float4      _CascadeShadowSplitSpheres0;
float4      _CascadeShadowSplitSpheres1;
float4      _CascadeShadowSplitSpheres2;
float4      _CascadeShadowSplitSpheres3;
float4      _CascadeShadowSplitSphereRadii;

float4      _MainLightShadowOffset0; // xy: offset0, zw: offset1
float4      _MainLightShadowOffset1; // xy: offset2, zw: offset3
float4      _MainLightShadowParams;   // (x: shadowStrength, y: >= 1.0 if soft shadows, 0.0 otherwise, z: main light fade scale, w: main light fade bias)
float4      _MainLightShadowmapSize;  // (xy: 1/width and 1/height, zw: width and height)

// float4      _AdditionalShadowOffset0; // xy: offset0, zw: offset1
// float4      _AdditionalShadowOffset1; // xy: offset2, zw: offset3
// float4      _AdditionalShadowFadeParams; // x: additional light fade scale, y: additional light fade bias, z: 0.0, w: 0.0)
// float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)

// #if defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
//     #if !USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
//     // Point lights can use 6 shadow slices. Some mobile GPUs performance decrease drastically with uniform
//     // blocks bigger than 8kb while others have a 64kb max uniform block size. This number ensures size of buffer
//     // AdditionalLightShadows stays reasonable. It also avoids shader compilation errors on SHADER_API_GLES30
//     // devices where max number of uniforms per shader GL_MAX_FRAGMENT_UNIFORM_VECTORS is low (224)
//     float4      _AdditionalShadowParams[MAX_VISIBLE_LIGHTS];         // Per-light data
//     float4x4    _AdditionalLightsWorldToShadow[MAX_VISIBLE_LIGHTS];  // Per-shadow-slice-data
//     #endif
// #endif

#ifndef SHADER_API_GLES3
CBUFFER_END
#endif

#if defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
    #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
        StructuredBuffer<float4>   _AdditionalShadowParams_SSBO;        // Per-light data - TODO: test if splitting _AdditionalShadowParams_SSBO[lightIndex].w into a separate StructuredBuffer<int> buffer is faster
        StructuredBuffer<float4x4> _AdditionalLightsWorldToShadow_SSBO; // Per-shadow-slice-data - A shadow casting light can have 6 shadow slices (if it's a point light)
    #endif
#endif

//=========== end from URP Shadows.hlsl

#include "../Lib/ShadowsLib.hlsl"

float4 _ShadowBias; // x: depth bias, y: normal bias
float _MainLightShadowOn; //send  from PowerUrpLitFeature

/**
only z,not enought
 */
// #define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0
#define BEYOND_SHADOW_FAR(shadowCoord) any(shadowCoord.xyz <= 0.0) || any(shadowCoord.xyz >= 1.0) 

float ComputeCascadeIndex(float3 positionWS)
{
    float3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
    float3 fromCenter1 = positionWS - _CascadeShadowSplitSpheres1.xyz;
    float3 fromCenter2 = positionWS - _CascadeShadowSplitSpheres2.xyz;
    float3 fromCenter3 = positionWS - _CascadeShadowSplitSpheres3.xyz;
    float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

    float4 weights = float4(distances2 < _CascadeShadowSplitSphereRadii);
    weights.yzw = saturate(weights.yzw - weights.xyz);

    return 4 - dot(weights, float4(4, 3, 2, 1));
}

/*
    call TransformWorldToShadowCoord in vs will be see artifact
    can call in ps
*/
float4 TransformWorldToShadowCoord(float3 positionWS)
{
#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
    float cascadeIndex = ComputeCascadeIndex(positionWS);
#else
    float cascadeIndex = 0;
#endif

    float4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));

    return float4(shadowCoord.xyz, cascadeIndex);
}


float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection,float matShadowNormalBias=0,float matShadowDepthBias=0)
{
    float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
    float scale = invNdotL * (_ShadowBias.y + matShadowNormalBias);

    // normal bias is negative since we want to apply an inset normal offset
    positionWS = lightDirection * (_ShadowBias.xxx + matShadowDepthBias) + positionWS;
    positionWS = normalWS * scale.xxx + positionWS;
    return positionWS;
}

float GetShadowFade(float3 positionWS)
{
    float3 camToPixel = positionWS - _WorldSpaceCameraPos;
    float distanceCamToPixel2 = dot(camToPixel, camToPixel);

    float fade = saturate(distanceCamToPixel2 * _MainLightShadowParams.z + _MainLightShadowParams.w);
    return fade;
}


float MixRealtimeAndBakedShadows(float realtimeShadow, float bakedShadow, float shadowFade)
{
#if defined(SHADOWS_FULL_MIX)
    return min(lerp(realtimeShadow, bakedShadow, shadowFade),bakedShadow);
#endif

#if defined(LIGHTMAP_SHADOW_MIXING)
    return min(lerp(realtimeShadow, 1, shadowFade), bakedShadow);
#else
    return lerp(realtimeShadow, bakedShadow, shadowFade);
#endif
}

float BakedShadow(float4 shadowMask, float4 occlusionProbeChannels)
{
    // Here occlusionProbeChannels used as mask selector to select shadows in shadowMask
    // If occlusionProbeChannels all components are zero we use default baked shadow value 1.0
    // This code is optimized for mobile platforms:
    // float bakedShadow = any(occlusionProbeChannels) ? dot(shadowMask, occlusionProbeChannels) : 1.0h;
    float bakedShadow = float(1.0) + dot(shadowMask - float(1.0), occlusionProbeChannels);
    return bakedShadow;
}

float CalcShadow(float4 shadowCoord,float3 worldPos,float4 shadowMask,float softScale)
{
    float shadow = 1;
    #if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    // if(receiveShadow){
        //shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture, shadowCoord.xyz);
        shadow = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture),shadowCoord,softScale);
        shadow = lerp(1,shadow,_MainLightShadowParams.x); // shadow intensity
        shadow = BEYOND_SHADOW_FAR(shadowCoord) ? 1 : shadow; // shadow range

        // baked shadow
        #if defined(CALCULATE_BAKED_SHADOWS)
            float bakedShadow = BakedShadow(shadowMask,_MainLightOcclusionProbes);
        #else
            float bakedShadow = 1;
        #endif

        // shadow fade
        float shadowFade = GetShadowFade(worldPos); 
        // shadowFade = shadowCoord.w == 4 ? 1.0 : shadowFade;
        // mix 
        shadow = MixRealtimeAndBakedShadows(shadow,bakedShadow,shadowFade);
    // }
    #endif 
    return shadow;
}
float CalcShadow (float4 shadowCoord,float3 worldPos,half mainLightShadowSoftScale=1)
{
    return CalcShadow(shadowCoord,worldPos,1,mainLightShadowSoftScale);
}

// obsolete (for compatible)
float CalcShadow (float4 shadowCoord,float3 worldPos,float4 shadowMask,bool isReceiveShadow,float softScale){
    return CalcShadow(shadowCoord,worldPos,shadowMask,softScale);
}

#define MainLightShadow(shadowCoord,worldPos,shadowMask,softScale) CalcShadow(shadowCoord,worldPos,shadowMask,softScale)

#endif //MAIN_LIGHT_SHADOW_HLSL