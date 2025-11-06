#if !defined(COORDINATE_SYSTEM_HLSL)
#define COORDINATE_SYSTEM_HLSL
#define PI2 6.283
/**
    demo:, rotate and strength
//============== Noise
    half2 noiseOffset = UVOffset(_NoiseTex_ST.zw, _NoiseTexOffsetStop);
//============== Polar or Cartesian
    float2 noiseUV = screenUV;
    #if defined(_NOISE_POLAR_UV)
        noiseUV = ToPolar(screenUV*2-1);
        noiseUV= noiseUV * _NoiseTex_ST.xy + noiseOffset;
        noiseUV = ToCartesian(noiseUV);
    #else
        noiseUV= noiseUV * _NoiseTex_ST.xy + noiseOffset;
    #endif
*/

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

/**
    hclip pos[-w,w] -> screen pos [0,1]
**/
float4 ComputeNormalizedScreenPos(float4 posCS){
    float4 pos = posCS * rcp(posCS.w);
    pos.xy = pos.xy * 0.5 + 0.5;
    // no gl
    #if defined(UNITY_UV_STARTS_AT_TOP)
        pos.y = 1- pos.y;
    #endif
    return pos;
}
#endif //COORDINATE_SYSTEM_HLSL