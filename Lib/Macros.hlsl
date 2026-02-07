#if !defined(MACROS_HLSL)
#define MACROS_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Macros.hlsl"

#define TEMPLATE_4_FLT(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4, FunctionBody) \
    float  FunctionName(float  Parameter1, float  Parameter2, float  Parameter3, float  Parameter4) { FunctionBody; } \
    float2 FunctionName(float2 Parameter1, float2 Parameter2, float2 Parameter3, float2  Parameter4) { FunctionBody; } \
    float3 FunctionName(float3 Parameter1, float3 Parameter2, float3 Parameter3, float3  Parameter4) { FunctionBody; } \
    float4 FunctionName(float4 Parameter1, float4 Parameter2, float4 Parameter3, float4  Parameter4) { FunctionBody; }

#define TEMPLATE_4_HALF(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4, FunctionBody) \
    half  FunctionName(half  Parameter1, half  Parameter2, half  Parameter3, half  Parameter4) { FunctionBody; } \
    half2 FunctionName(half2 Parameter1, half2 Parameter2, half2 Parameter3, half2 Parameter4) { FunctionBody; } \
    half3 FunctionName(half3 Parameter1, half3 Parameter2, half3 Parameter3, half3 Parameter4) { FunctionBody; } \
    half4 FunctionName(half4 Parameter1, half4 Parameter2, half4 Parameter3, half4 Parameter4) { FunctionBody; } \
    float  FunctionName(float  Parameter1, float  Parameter2, float  Parameter3, float  Parameter4) { FunctionBody; } \
    float2 FunctionName(float2 Parameter1, float2 Parameter2, float2 Parameter3, float2  Parameter4) { FunctionBody; } \
    float3 FunctionName(float3 Parameter1, float3 Parameter2, float3 Parameter3, float3  Parameter4) { FunctionBody; } \
    float4 FunctionName(float4 Parameter1, float4 Parameter2, float4 Parameter3, float4  Parameter4) { FunctionBody; }

#ifdef SHADER_API_GLES
    #define TEMPLATE_4_INT(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4, FunctionBody) \
    int    FunctionName(int    Parameter1, int    Parameter2, int    Parameter3, int  Parameter4) { FunctionBody; } \
    int2   FunctionName(int2   Parameter1, int2   Parameter2, int2   Parameter3, int2  Parameter4) { FunctionBody; } \
    int3   FunctionName(int3   Parameter1, int3   Parameter2, int3   Parameter3, int3  Parameter4) { FunctionBody; } \
    int4   FunctionName(int4   Parameter1, int4   Parameter2, int4   Parameter3, int4  Parameter4) { FunctionBody; }
#else
    #define TEMPLATE_4_INT(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4, FunctionBody) \
    int    FunctionName(int    Parameter1, int    Parameter2, int    Parameter3, int  Parameter4) { FunctionBody; } \
    int2   FunctionName(int2   Parameter1, int2   Parameter2, int2   Parameter3, int2  Parameter4) { FunctionBody; } \
    int3   FunctionName(int3   Parameter1, int3   Parameter2, int3   Parameter3, int3  Parameter4) { FunctionBody; } \
    int4   FunctionName(int4   Parameter1, int4   Parameter2, int4   Parameter3, int4  Parameter4) { FunctionBody; } \
    uint   FunctionName(uint   Parameter1, uint   Parameter2, uint   Parameter3, uint  Parameter4) { FunctionBody; } \
    uint2  FunctionName(uint2  Parameter1, uint2  Parameter2, uint2  Parameter3, uint2  Parameter4) { FunctionBody; } \
    uint3  FunctionName(uint3  Parameter1, uint3  Parameter2, uint3  Parameter3, uint3  Parameter4) { FunctionBody; } \
    uint4  FunctionName(uint4  Parameter1, uint4  Parameter2, uint4  Parameter3, uint4  Parameter4) { FunctionBody; }
#endif    

#define TEMPLATE_5_FLT(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4,Parameter5, FunctionBody) \
    float  FunctionName(float  Parameter1, float  Parameter2, float  Parameter3, float  Parameter4, float  Parameter5) { FunctionBody; } \
    float2 FunctionName(float2 Parameter1, float2 Parameter2, float2 Parameter3, float  Parameter4, float2  Parameter5) { FunctionBody; } \
    float3 FunctionName(float3 Parameter1, float3 Parameter2, float3 Parameter3, float  Parameter4, float3  Parameter5) { FunctionBody; } \
    float4 FunctionName(float4 Parameter1, float4 Parameter2, float4 Parameter3, float  Parameter4, float4  Parameter5) { FunctionBody; }

#define TEMPLATE_5_HALF(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4,Parameter5, FunctionBody) \
    half  FunctionName(half  Parameter1, half  Parameter2, half  Parameter3, half  Parameter4, half  Parameter5) { FunctionBody; } \
    half2 FunctionName(half2 Parameter1, half2 Parameter2, half2 Parameter3, half2  Parameter4, half2  Parameter5) { FunctionBody; } \
    half3 FunctionName(half3 Parameter1, half3 Parameter2, half3 Parameter3, half3  Parameter4, half3  Parameter5) { FunctionBody; } \
    half4 FunctionName(half4 Parameter1, half4 Parameter2, half4 Parameter3, half4  Parameter4, half4  Parameter5) { FunctionBody; } \
    float  FunctionName(float  Parameter1, float  Parameter2, float  Parameter3, float  Parameter4, float  Parameter5) { FunctionBody; } \
    float2 FunctionName(float2 Parameter1, float2 Parameter2, float2 Parameter3, float  Parameter4, float2  Parameter5) { FunctionBody; } \
    float3 FunctionName(float3 Parameter1, float3 Parameter2, float3 Parameter3, float  Parameter4, float3  Parameter5) { FunctionBody; } \
    float4 FunctionName(float4 Parameter1, float4 Parameter2, float4 Parameter3, float  Parameter4, float4  Parameter5) { FunctionBody; }

#ifdef SHADER_API_GLES
    #define TEMPLATE_5_INT(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4,Parameter5, FunctionBody) \
    int    FunctionName(int    Parameter1, int    Parameter2, int    Parameter3,int    Parameter4,int    Parameter5) { FunctionBody; } \
    int2   FunctionName(int2   Parameter1, int2   Parameter2, int2   Parameter3,int2    Parameter4,int2    Parameter5) { FunctionBody; } \
    int3   FunctionName(int3   Parameter1, int3   Parameter2, int3   Parameter3,int3    Parameter4,int3    Parameter5) { FunctionBody; } \
    int4   FunctionName(int4   Parameter1, int4   Parameter2, int4   Parameter3,int4    Parameter4,int4    Parameter5) { FunctionBody; }
#else
    #define TEMPLATE_5_INT(FunctionName, Parameter1, Parameter2, Parameter3,Parameter4,Parameter5, FunctionBody) \
    int    FunctionName(int    Parameter1, int    Parameter2, int    Parameter3,int    Parameter4,int    Parameter5) { FunctionBody; } \
    int2   FunctionName(int2   Parameter1, int2   Parameter2, int2   Parameter3,int2    Parameter4,int2    Parameter5) { FunctionBody; } \
    int3   FunctionName(int3   Parameter1, int3   Parameter2, int3   Parameter3,int3    Parameter4,int3    Parameter5) { FunctionBody; } \
    int4   FunctionName(int4   Parameter1, int4   Parameter2, int4   Parameter3,int4    Parameter4,int4    Parameter5) { FunctionBody; }\
    uint   FunctionName(uint   Parameter1, uint   Parameter2, uint   Parameter3,uint    Parameter4,uint Parameter5) { FunctionBody; } \
    uint2  FunctionName(uint2  Parameter1, uint2  Parameter2, uint2  Parameter3,uint2    Parameter4,uint2    Parameter5) { FunctionBody; } \
    uint3  FunctionName(uint3  Parameter1, uint3  Parameter2, uint3  Parameter3,uint3    Parameter4,uint3    Parameter5) { FunctionBody; } \
    uint4  FunctionName(uint4  Parameter1, uint4  Parameter2, uint4  Parameter3,uint4    Parameter4,uint4    Parameter5) { FunctionBody; }
#endif

//================================ Functions
// min3, avoid urp Common/Min3
TEMPLATE_3_FLT(min3, a, b, c, return min(min(a, b), c))
TEMPLATE_3_INT(min3, a, b, c, return min(min(a, b), c))
TEMPLATE_3_FLT(max3, a, b, c, return max(max(a, b), c))
TEMPLATE_3_INT(max3, a, b, c, return max(max(a, b), c))

TEMPLATE_4_FLT(Min4, a, b, c,d, return min(min3(a, b,c), d))
TEMPLATE_4_INT(Min4, a, b, c,d, return min(min3(a, b,c), d))
TEMPLATE_4_FLT(Max4, a, b, c,d, return max(max3(a, b,c), d))
TEMPLATE_4_INT(Max4, a, b, c,d, return max(max3(a, b,c), d))

TEMPLATE_5_FLT(Min5, a, b, c,d,e, return min(Min4(a, b,c,d), e))
TEMPLATE_5_INT(Min5, a, b, c,d,e, return min(Min4(a, b,c,d), e))
TEMPLATE_5_FLT(Max5, a, b, c,d,e, return max(Max4(a, b,c,d), e))
TEMPLATE_5_INT(Max5, a, b, c,d,e, return max(Max4(a, b,c,d), e))

#endif // MACROS_HLSL