#if !defined(BIG_SHADOWS_HLSL)
#define BIG_SHADOWS_HLSL
#include "UnityLib.hlsl"

#define _MainLightShadowmapSize _BigShadowMap_TexelSize
#define SHADOW_INTENSITY saturate(_BigShadowParams.x)


float4 _BigShadowMap_TexelSize;
#include "ShadowsLib.hlsl"

TEXTURE2D_SHADOW(_BigShadowMap); SAMPLER_CMP(sampler_BigShadowMap);

float4x4 _BigShadowVP;
float4 _BigShadowParams; //{x: shadow intensity}
half _BigShadowOn;

float3 TransformWorldToBigShadow(float3 worldPos){
    float3 bigShadowCoord = mul(_BigShadowVP,float4(worldPos,1)).xyz;
    return bigShadowCoord;
}

// #define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0

/**
    _SHADOWS_SOFT for soft shadow 
*/
float CalcBigShadowAtten(float3 bigShadowCoord,float softScale){
    branch_if(any(bigShadowCoord <= 0) || any(bigShadowCoord >= 1))
        return 1;
    
    float shadow = SampleShadowmap(TEXTURE2D_ARGS(_BigShadowMap,sampler_BigShadowMap),bigShadowCoord.xyzx,softScale);
    shadow = lerp(1,shadow,SHADOW_INTENSITY * _BigShadowOn);

    return shadow;   
}

/**
    ApplyDistanceAtten(mainLight.shadowAttenuation,worldPos,_WorldSpaceCameraPos,10);
*/
void ApplyDistanceAtten(inout float bigShadowAtten,float3 worldPos,float3 camPos,float dist,float fadeWidth = 10){
    float3 camDir = worldPos - camPos;
    float camDist2 = dot(camDir,camDir);
    bigShadowAtten = lerp(bigShadowAtten,1,smoothstep(0,fadeWidth,camDist2 - dist*dist ));
}


#endif // BIG_SHADOWS_HLSL