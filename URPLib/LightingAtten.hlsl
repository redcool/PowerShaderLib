#if !defined(LIGHTING_ATTEN_HLSL)
#define LIGHTING_ATTEN_HLSL

/**
    Distance atten

    https://lisyarus.github.io/blog/posts/point-light-attenuation.html

float DistanceAtten(float distance,float radius,float maxIntensity,float fallOff){
    float s = distance/radius;
    float isInner = s<1;

    float s2 = Sqr(s);
    float atten = maxIntensity * Sqr(1 - s2)/(1+fallOff*s2);
    return atten * isInner;
}
*/
float Sqr(float x){
     return x*x;
}
float DistanceAtten(float distance2,float radius2,float maxIntensity,float fallOff=1){
    float s2 = distance2/radius2;
    float isInner = s2<1;

    float atten = maxIntensity * Sqr(1 - s2)/(1+fallOff*s2);
    return atten * isInner;
}

float AngleAtten(float3 spotDir,float3 lightDir,float outerAngleCos ,float innerAngleCos){
    float atten = (dot(spotDir,lightDir));
    atten *= smoothstep(outerAngleCos,innerAngleCos,atten);
    return atten;
}

/**
* Calculate spot light angles
* @param spotLightAngle outer and inner spot angles in dot product form
* @return normalized spot light angles

Curve show:
https://www.desmos.com/calculator/wemfnwcskg?lang=zh-CN

original : cos(radians(spotLightAngle) * 0.5) , cos[0,1.57] = [1,0] , cos atten curve
simplify : 1 - (radians(spotLightAngle))/6.28 : [1,0] ,linear atten curve
*/
float2 CalcSpotLightAngleAtten(float2 spotLightAngle){
    return 1- radians(spotLightAngle)/6.28;
    return cos(radians(spotLightAngle) * 0.5);
}
#endif //LIGHTING_ATTEN_HLSL