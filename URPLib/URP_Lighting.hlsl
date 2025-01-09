/*
    keywords:
    ADDITIONAL_LIGHT_CALCULATE_SHADOWS
*/
#if !defined(URP_LIGHTING_HLSL)
#define URP_LIGHTING_HLSL

#include "URP_AdditionalLightShadows.hlsl"
#include "../Lib/RenderingLayer.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                          Light Helpers                                    //
///////////////////////////////////////////////////////////////////////////////

// Abstraction over Light shading data.
struct Light
{
    float3   direction;
    float3   color;
    float    distanceAttenuation;
    float    shadowAttenuation;
    uint layerMask;
};



///////////////////////////////////////////////////////////////////////////////
//                        Attenuation Functions                               /
///////////////////////////////////////////////////////////////////////////////
#if !defined(SHADER_HINT_NICE_QUALITY)
    #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
        #define SHADER_HINT_NICE_QUALITY 0
    #else
        #define SHADER_HINT_NICE_QUALITY 1
    #endif
#endif
// Matches Unity Vanila attenuation
// Attenuation smoothly decreases to light range.
float DistanceAttenuation(float distanceSqr, float2 distanceAttenuation)
{
    // We use a shared distance attenuation for additional directional and puctual lights
    // for directional lights attenuation will be 1
    float lightAtten = rcp(distanceSqr);
#if SHADER_HINT_NICE_QUALITY
    // Use the smoothing factor also used in the Unity lightmapper.
    float factor = distanceSqr * distanceAttenuation.x;
    float smoothFactor = saturate(1.0h - factor * factor);
    smoothFactor = smoothFactor * smoothFactor;
#else
    // We need to smoothly fade attenuation to light range. We start fading linearly at 80% of light range
    // Therefore:
    // fadeDistance = (0.8 * 0.8 * lightRangeSq)
    // smoothFactor = (lightRangeSqr - distanceSqr) / (lightRangeSqr - fadeDistance)
    // We can rewrite that to fit a MAD by doing
    // distanceSqr * (1.0 / (fadeDistanceSqr - lightRangeSqr)) + (-lightRangeSqr / (fadeDistanceSqr - lightRangeSqr)
    // distanceSqr *        distanceAttenuation.y            +             distanceAttenuation.z
    float smoothFactor = saturate(distanceSqr * distanceAttenuation.x + distanceAttenuation.y);
#endif

    return lightAtten * smoothFactor;
}

float AngleAttenuation(float3 spotDirection, float3 lightDirection, float2 spotAttenuation)
{
    // Spot Attenuation with a linear falloff can be defined as
    // (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
    // This can be rewritten as
    // invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
    // SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
    // SdotL * spotAttenuation.x + spotAttenuation.y

    // If we precompute the terms in a MAD instruction
    float SdotL = dot(spotDirection, lightDirection);
    float atten = saturate(SdotL * spotAttenuation.x + spotAttenuation.y);
    return atten * atten;
}


Light GetMainLight()
{
    Light light;
    light.direction = _MainLightPosition.xyz;
#if USE_CLUSTERED_LIGHTING
    light.distanceAttenuation = 1.0;
#else
    // float4(currentLightIndexOffset,currentLightIndexCount,mainLightStrength,0)
    light.distanceAttenuation = unity_LightData.z; // unity_LightData.z is 1 when not culled by the culling mask, otherwise 0.
#endif
    light.shadowAttenuation = 1.0;
    light.color = _MainLightColor.rgb;
    light.layerMask = _MainLightLayerMask;

// #ifdef _LIGHT_LAYERS
// #else
//     light.layerMask = DEFAULT_LIGHT_LAYERS;
// #endif
    light.distanceAttenuation *= IsMatchRenderingLayer(light.layerMask);

    return light;
}

Light GetMainLight(float4 shadowCoord,float3 positionWS,half softScale=1){
    Light light = GetMainLight();
    light.shadowAttenuation = CalcShadow(shadowCoord,positionWS,softScale);
    return light;
}

Light GetMainLight(float4 shadowCoord, float3 positionWS, half4 shadowMask,half softScale=1)
{
    Light light = GetMainLight();
    light.shadowAttenuation = MainLightShadow(shadowCoord, positionWS, shadowMask,softScale);

    #if defined(_LIGHT_COOKIES)
        real3 cookieColor = SampleMainLightCookie(positionWS);
        light.color *= cookieColor;
    #endif

    return light;
}

// Fills a light struct given a perObjectLightIndex
Light GetAdditionalPerObjectLight(int perObjectLightIndex, float3 positionWS)
{
    // Abstraction over Light input constants
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    float4 lightPositionWS = _AdditionalLightsBuffer[perObjectLightIndex].position;
    float3 color = _AdditionalLightsBuffer[perObjectLightIndex].color.rgb;
    float4 distanceAndSpotAttenuation = _AdditionalLightsBuffer[perObjectLightIndex].attenuation;
    float4 spotDirection = _AdditionalLightsBuffer[perObjectLightIndex].spotDirection;
    uint lightLayerMask = _AdditionalLightsBuffer[perObjectLightIndex].layerMask;
#else
    float4 lightPositionWS = _AdditionalLightsPosition[perObjectLightIndex];
    float3 color = _AdditionalLightsColor[perObjectLightIndex].rgb;
    float4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[perObjectLightIndex];
    float4 spotDirection = _AdditionalLightsSpotDir[perObjectLightIndex];
    uint lightLayerMask = asuint(_AdditionalLightsLayerMasks[perObjectLightIndex]);
#endif

    // Directional lights store direction in lightPosition.xyz and have .w set to 0.0.
    // This way the following code will work for both directional and punctual lights.
    float3 lightVector = lightPositionWS.xyz - positionWS * lightPositionWS.w;
    float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

    float3 lightDirection = float3(lightVector * rsqrt(distanceSqr));
    float attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy) * AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);

    Light light;
    light.direction = lightDirection;
    light.distanceAttenuation = saturate(attenuation);
    light.shadowAttenuation = 1.0;
    light.color = color;
    light.layerMask = lightLayerMask;

    return light;
}

uint GetPerObjectLightIndexOffset()
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    return unity_LightData.x;
#else
    return 0;
#endif
}

// Returns a per-object index given a loop index.
// This abstract the underlying data implementation for storing lights/light indices
int GetPerObjectLightIndex(uint index)
{
    
/////////////////////////////////////////////////////////////////////////////////////////////
// Structured Buffer Path                                                                   /
//                                                                                          /
// Lights and light indices are stored in StructuredBuffer. We can just index them.         /
// Currently all non-mobile platforms take this path :(                                     /
// There are limitation in mobile GPUs to use SSBO (performance / no vertex shader support) /
/////////////////////////////////////////////////////////////////////////////////////////////
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    uint offset = unity_LightData.x;
    return _AdditionalLightsIndices[offset + index];

/////////////////////////////////////////////////////////////////////////////////////////////
// UBO path                                                                                 /
//                                                                                          /
// We store 8 light indices in float4 unity_LightIndices[2];                                /
// Due to memory alignment unity doesn't support int[] or float[]                           /
// Even trying to reinterpret cast the unity_LightIndices to float[] won't work             /
// it will cast to float4[] and create extra register pressure. :(                          /
/////////////////////////////////////////////////////////////////////////////////////////////
#elif !defined(SHADER_API_GLES)
    // since index is uint shader compiler will implement
    // div & mod as bitfield ops (shift and mask).

    // TODO: Can we index a float4? Currently compiler is
    // replacing unity_LightIndicesX[i] with a dp4 with identity matrix.
    // u_xlat16_40 = dot(unity_LightIndices[int(u_xlatu13)], ImmCB_0_0_0[u_xlati1]);
    // This increases both arithmetic and register pressure.
    return unity_LightIndices[index / 4][index % 4];
#else
    // Fallback to GLES2. No bitfield magic here :(.
    // We limit to 4 indices per object and only sample unity_4LightIndices0.
    // Conditional moves are branch free even on mali-400
    // small arithmetic cost but no extra register pressure from ImmCB_0_0_0 matrix.
    float2 lightIndex2 = (index < 2.0h) ? unity_LightIndices[0].xy : unity_LightIndices[0].zw;
    float i_rem = (index < 2.0h) ? index : index - 2.0h;
    return (i_rem < 1.0h) ? lightIndex2.x : lightIndex2.y;
#endif
}

Light GetAdditionalLight(uint i, float3 positionWS,float softScale=1,bool isCalcShadows=false)
{
    #if USE_CLUSTERED_LIGHTING
        int lightIndex = i;
    #else
        int lightIndex = GetPerObjectLightIndex(i);
    #endif
    Light light = GetAdditionalPerObjectLight(lightIndex, positionWS);
    #if defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
        branch_if(isCalcShadows)
        light.shadowAttenuation = AdditionalLightRealtimeShadow(lightIndex, positionWS,softScale);
    #endif
    return light;
}

// Fills a light struct given a loop i index. This will convert the i
// index to a perObjectLightIndex
Light GetAdditionalLight(uint i, float3 positionWS,float4 shadowMask,float softScale=1,bool isCalcShadows=false)
{
    int perObjectLightIndex = GetPerObjectLightIndex(i);
    Light light = GetAdditionalPerObjectLight(perObjectLightIndex, positionWS);

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    float4 occlusionProbeChannels = _AdditionalLightsBuffer[perObjectLightIndex].occlusionProbeChannels;
#else
    float4 occlusionProbeChannels = _AdditionalLightsOcclusionProbes[perObjectLightIndex];
#endif

    light.shadowAttenuation = 1;
    #if defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
        branch_if(isCalcShadows)
        light.shadowAttenuation = AdditionalLightShadow(perObjectLightIndex, positionWS,shadowMask,occlusionProbeChannels,softScale,light.direction);
    #endif

    return light;
}


int GetAdditionalLightsCount()
{
    // TODO: we need to expose in SRP api an ability for the pipeline cap the amount of lights
    // in the culling. This way we could do the loop branch with an uniform
    // This would be helpful to support baking exceeding lights in SH as well
    return min(_AdditionalLightsCount.x, unity_LightData.y);
}

#endif //URP_LIGHTING_HLSL