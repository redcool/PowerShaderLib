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

float AngleAtten(float3 spotDir,float3 lightDir,float outerAngle ,float innerAngle){
    float atten = (dot(spotDir,lightDir));
    atten *= smoothstep(outerAngle,innerAngle,atten);
    return atten;
}

/**
* Calculate spot light angles
* @param spotLightAngle outer and inner spot angles in dot product form
* @return normalized spot light angles

original : cos(radians(spotLightAngle) * 0.5) , cos[0,1.57] = [1,0]
simplify : 1 - (radians(spotLightAngle))/3.14 : [1,0]
*/
float2 CalcSpotLightAngle(float2 spotLightAngle){
    return 1- radians(spotLightAngle)/3.14;
    return cos(radians(spotLightAngle) * 0.5);
}
#endif //LIGHTING_ATTEN_HLSL