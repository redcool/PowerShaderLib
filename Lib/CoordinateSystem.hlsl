#if !defined(COORDINATE_SYSTEM_HLSL)
#define COORDINATE_SYSTEM_HLSL
#define PI2 6.283

/**
    return {x:[-.5,.5],y:uv length}

    testcase
    
    float2 uv = i.uv;
    uv = (uv-0.5)*2;
    float2 puv = ToPolar(uv);
    puv.x *=3;
    puv.x += sin(_Time.x)*puv.y;

    puv = ToCartesian(puv);
    return float4(frac(puv),0,1);
*/
float2 ToPolar(float2 uv){
    float dist = length(uv);
    float angle = atan2(uv.y,uv.x);
    return float2(angle/PI2,dist);
}


/**
    uv.x[-.5,.5],uv.y : length

    float2 polar = ToPolar(i.uv);
    polar.x += _Angle;//[0,1]
    float2 coord = ToCartesian(polar);
*/
float2 ToCartesian(float2 uv){
    float c,s;
    sincos(uv.x*PI2,s,c);
    return float2(c,s) * uv.y;
}
#endif //COORDINATE_SYSTEM_HLSL