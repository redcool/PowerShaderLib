/**
    keywords:
    LIGHTMAP_ON

*/
#if !defined(LIGHTING_HLSL)
#define LIGHTING_HLSL

#include "URP_Input.hlsl"
#include "URP_GI.hlsl"
#include "URP_Lighting.hlsl"

float3 CalcLight(Light light,float3 diffColor,float3 specColor,float3 n,float3 v,float a,float a2){
    // if(!light.distanceAttenuation)
    //     return 0;
        
    float3 l = light.direction;
    float3 h = normalize(l+v);
    float nl = saturate(dot(n,l));

    float nh = saturate(dot(n,h));
    float lh = saturate(dot(l,h));

    float d = nh*nh*(a2 - 1) +1;
    float specTerm = a2/(d*d * max(0.001,lh*lh) * (4*a+2));
    float radiance = nl * light.shadowAttenuation * light.distanceAttenuation;
    return (diffColor + specColor * specTerm) * light.color * radiance;
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