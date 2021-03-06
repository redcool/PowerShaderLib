#if !defined(NOISE_LIB_HLSL)
#define NOISE_LIB_HLSL

//================= 
// white noise macros
//================= 
#define AMPLIFY 143758.5453
#define DELTA1_1 3.9812
#define DELTA1_2 7.1536
#define DELTA1_3 5.7241

#define DELTA2_1 float2(12.9898,78.233)
#define DELTA2_2 float2(39.346, 11.135)
#define DELTA2_3 float2(73.156, 52.235)

#define DELTA3_1 float3(12.9898, 78.233, 37.719)
#define DELTA3_2 float3(39.346, 11.135, 83.155)
#define DELTA3_3 float3(73.156, 52.235, 09.151)

//================= 
// white noise (1d,2d,3d)
//================= 
// N dim to 1d
#define N1(v,delta) frac(sin(dot(v,delta)) * AMPLIFY)

#define N11(v) N1(v.x,0.546)
#define N12(v) float2(N1(v.x,DELTA1_1),N1(v.x,DELTA1_2))
#define N13(v) float3(N1(v.x,DELTA1_1),N1(v.x,DELTA1_2),N1(v.x,DELTA1_3))

#define N21(v) N1(v.xy,DELTA2_1)
#define N22(v) float2(N1(v.xy,DELTA2_1),N1(v.xy,DELTA2_2))
#define N23(v) float3(N1(v.xy,DELTA2_1),N1(v.xy,DELTA2_2),N1(v.xy,DELTA2_3))

#define N31(v) N1(v.xyz,DELTA3_1)
#define N32(v) float2(N1(v.xyz,DELTA3_1),N1(v.xyz,DELTA3_2))
#define N33(v) float3(N1(v.xyz,DELTA3_1),N1(v.xyz,DELTA3_2),N1(v.xyz,DELTA3_3))

//================= 
// Easing macros
//================= 

#define EaseIn(v) v*v
#define EaseOut(v) 1-EaseIn(1-v)
#define EaseInOut(v) lerp(EaseIn(v),EaseOut(v),v)

//================= 
// value noise 2d
//================= 
float ValueNoise(float2 uv){
    float2 i = floor(uv);
    float2 p = frac(uv);
    p = p*p*(3-2*p);

    float a = N21(i);
    float b = N21(i+float2(1,0));
    float c = N21(i+float2(0,1));
    float d = N21(i+float2(1,1));
    return lerp(lerp(a,b,p.x),lerp(c,d,p.x),p.y);
}

float SmoothValueNoise(float2 uv){
    return 
        (ValueNoise(uv * 4) + 
        ValueNoise(uv * 8) * 0.5 +
        ValueNoise(uv * 16) * 0.25 + 
        ValueNoise(uv * 32) * 0.0625)*0.5;
}

#define ValueNoise2(uv,n_out) \
    float2 id = floor(uv);\
    float2 p = frac(uv);\
    p = p*p*(3-2*p);\
    n_out = lerp(lerp(N21(id),N21(id+float2(1,0)),p.x),lerp(N21(id+float2(0,1)),N21(id+float2(1,1)),p.x),p.y)


//================= 
// ValueNoise Macros
//================= 
#define floatN(n) float##n
#define N3x(x) N3##x
#define ValueNoise3x(v,num,noise_out) \
    float3 id = floor(v);\
    float3 p = frac(v);\
    p = p*p*(3-2*p);\
    floatN(num) result[2];\
    [unroll]for(int z=0;z<2;z++)\
        result[z] = lerp(lerp(N3x(num)(id+float3(0,0,z)),N3x(num)(id+float3(1,0,z)),p.x),lerp(N3x(num)(id+float3(0,1,z)),N3x(num)(id+float3(1,1,z)),p.x),p.y);\
    noise_out = lerp(result[0],result[1],p.z)

//================= 
// ValueNoise functions
//================= 
float ValueNoise31(float3 v){
    float n=0;
    ValueNoise3x(v,1,n);
    return n;
}
float2 ValueNoise32(float3 v){
    float2 n=0;
    ValueNoise3x(v,2,n);
    return n;
}
float3 ValueNoise33(float3 v){
    float3 n=0;
    ValueNoise3x(v,3,n);
    return n;
}

//================= 
// value noise 3d original version
//=================  
/**
float3 ValueNoise33(float3 v){
    float3 i = floor(v);
    float3 p = frac(v);
    p = p*p*(3-2*p);

    float3 n[2];

    [unroll]
    for(int z=0;z<2;z++){
        float3 a = N33(i + float3(0,0,z));
        float3 b = N33(i + float3(1,0,z));
        float3 c = N33(i + float3(0,1,z));
        float3 d = N33(i + float3(1,1,z));

        n[z] = lerp(lerp(a,b,p.x),lerp(c,d,p.x),p.y);
    }
    return lerp(n[0],n[1],p.z);
}
*/

//================= 
// perlin noise
//=================  
float GradientNoise(float v){
    float p = frac(v);

    float prevCellInclination = N11(floor(v)) * 2-1;
    float prevCellPoint = prevCellInclination * p;

    return prevCellPoint;
}

#endif //NOISE_LIB_HLSL