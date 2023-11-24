/**
    keywords:
    LIGHTMAP_ON

*/
#if !defined(LIGHTING_HLSL)
#define LIGHTING_HLSL

#include "URP_Input.hlsl"
#include "URP_GI.hlsl"
#include "URP_Lighting.hlsl"

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
    float d = nh*nh*(a2 - 1) +1;
    float specTerm = a2/(d*d * max(0.001,lh*lh) * (4*a+2));
    float radiance = nl * light.shadowAttenuation * light.distanceAttenuation;
    return (diffColor + specColor * specTerm) * light.color * radiance;
}

/**
    Calc directColor
*/
half3 CalcLight(Light light,half3 diffColor,half3 specColor,float3 n,float3 v,float a,float a2){
    // if(!light.distanceAttenuation)
    //     return 0;
    half nl,nh,lh;
    CalcBRDFWeights(nl/**/,nh/**/,lh/**/,light.direction,n,v);
    return CalcLight(light,diffColor,specColor,nl,nh,lh,a,a2);
}


float3 CalcAdditionalLights(float3 worldPos,float3 diffColor,float3 specColor,float3 n,float3 v,float a,float a2,float4 shadowMask,float softScale=1 ){
    uint count = GetAdditionalLightsCount();
    float3 c = 0;
    for(uint i=0;i<count;i++){
        Light l = GetAdditionalLight(i,worldPos,shadowMask,softScale);
        c += CalcLight(l,diffColor,specColor,n,v,a,a2);
    }
    return c;
}




#endif //LIGHTING_HLSL