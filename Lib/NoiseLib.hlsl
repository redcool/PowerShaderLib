#if !defined(NOISE_LIB_HLSL)
#define NOISE_LIB_HLSL

//---------------- Noise 
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


#endif //NOISE_LIB_HLSL