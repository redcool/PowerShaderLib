/**
    keywords:
    LIGHTMAP_ON

*/
#if !defined(LIGHTING_HLSL)
#define LIGHTING_HLSL

#include "URP_Input.hlsl"
#include "URP_GI.hlsl"
#include "URP_Lighting.hlsl"
#include "../Lib/BSDF.hlsl"
#include "LightingAtten.hlsl"

#define CHANGE_LIGHT_COLOR 0
#define CHANGE_SPECULAR_COLOR 1

void OffsetLight(inout float3 lightDir,inout float3 lightColor,inout float3 specularColor,half colorChangeMode,half3 newDir,half3 newColor){
    lightDir = (newDir.xyz);
    lightColor= colorChangeMode == 0 ? newColor : lightColor;
    specularColor *= colorChangeMode == 1? newColor : 1;
}

void OffsetLight(inout Light light,inout float3 specularColor,half colorChangeMode,half3 newDir,half3 newColor){
    OffsetLight(light.direction,light.color,specularColor,colorChangeMode,newDir,newColor);
}

/**
    calc nl,nh,lh
*/
void CalcBRDFWeights(out float nl,out float nh,out float lh,float3 l,float3 n,float3 v){
    float3 h = normalize(l+v);
    nl = saturate(dot(n,l));
    nh = saturate(dot(n,h));
    lh = saturate(dot(l,h));
}

/**
    Calc directColor
*/
half3 CalcLight(Light light,half3 diffColor,half3 specColor,float nl,float nh,float lh,float a,float a2){
    float specTerm = MinimalistCookTorrance(nh,lh,a,a2);
    float radiance = nl * light.shadowAttenuation * light.distanceAttenuation;
    return (diffColor + specColor * specTerm) * light.color * radiance;
}

/**
    Calc directColor
*/
half3 CalcLight(Light light,half3 diffColor,half3 specColor,float3 n,float3 v,float a,float a2){
    if(!light.distanceAttenuation)
        return 0;
    
    half nl,nh,lh;
    CalcBRDFWeights(nl/**/,nh/**/,lh/**/,light.direction,n,v);
    return CalcLight(light,diffColor,specColor,nl,nh,lh,a,a2);
}


float3 CalcAdditionalLights(
    float3 worldPos,
    float3 diffColor,
    float3 specColor,
    float3 n,
    float3 v,
    float a, 
    float a2,
    float4 shadowMask,
    float softScale=1,
    bool isCalcLights = true,
    bool isCalcShadows = true
    )
    {
    uint count = GetAdditionalLightsCount() * isCalcLights;

    float3 c = 0;
    for(uint i=0;i<count;i++){
        Light l = GetAdditionalLight(i,worldPos,shadowMask,softScale,isCalcShadows);
        if(IsMatchRenderingLayer(l.layerMask))
            c += CalcLight(l,diffColor,specColor,n,v,a,a2);
    }
    return c;
}


/**
    Get Light for(dir,spot,point)

    // demo
    check DeferredLighting.cs
    //======== use urp atten or use LightingAtten.hlsl
    #define UNITY_ATTEN

    //======== params
    float4 lightPos : light world position, dir light w=0
    float3 color : light color
    float shadowAtten : light shadowMap attenuation
    float3 worldPos : vertex' world position
    float4 distanceAndSpotAttenuation : {xy: distance(point,spot), zw:angle(spot)}, UNITY_ATTEN only
    float3 spotLightDir : spot light direction
    float radius : light's range
    float intensity : light 's intensity
    float falloff : custom falloff
    bool isSpot : is spot
    float2 spotLightAngleCos : spot light angle cos(outer angle,inner angle)
*/
Light GetLight(float4 lightPos,float3 color,float shadowAtten,float3 worldPos,float4 distanceAndSpotAttenuation,float3 spotLightDir
,float radius,float intensity,float falloff,bool isSpot,float2 spotLightAngleCos
){
    float3 lightDir = lightPos.xyz - worldPos * lightPos.w;
    float distSqr = max(dot(lightDir,lightDir),HALF_MIN);

    lightDir = lightDir * rsqrt(distSqr);
    float atten = 1;
    #if defined(UNITY_ATTEN)
        atten *= DistanceAttenuation(distSqr,distanceAndSpotAttenuation.xy);
        atten *= AngleAttenuation(spotLightDir,lightDir,distanceAndSpotAttenuation.zw);
    #else
        atten *= DistanceAtten(distSqr,radius*radius,intensity,falloff);
        atten *= isSpot ? AngleAtten(spotLightDir,lightDir,spotLightAngleCos.x,spotLightAngleCos.y) : 1;
    #endif

    Light l = (Light)0;
    l.direction = lightDir;
    l.color = color;
    // l.distanceAttenuation = saturate(atten) + (1-lightPos.w);
    l.distanceAttenuation = lightPos.w ? saturate(atten) : 1;
    l.shadowAttenuation = shadowAtten;
    return l;
}

#endif //LIGHTING_HLSL