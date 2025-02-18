/**
    use urp or simplified

    macros:
    _TEST
*/

#include "UnityCGCompatible.hlsl"
#include "Project/ProjectMacros.hlsl"

// #define USE_URP // uncomment this use urp flow
#if defined(USE_URP)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #define UNITY_LIB_HLSL
#endif

#if !defined(UNITY_LIB_HLSL)
#define UNITY_LIB_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Version.hlsl"

#define TRANSFORM_TEX(tex, name) ((tex.xy) * name##_ST.xy + name##_ST.zw)

#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

// #define CBUFFER_START(name) cbuffer name {
// #define CBUFFER_END };

float4 _MainLightPosition;
half4 _MainLightColor;

#if defined(DRP)
float4 _WorldSpaceLightPos0;
half4 _LightColor0;
#define _MainLightPosition _WorldSpaceLightPos0
#define _MainLightColor _LightColor0
#endif

#define branch_if UNITY_BRANCH if

//////////// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
// Time (t = time since current level load) values from Unity
float4 _Time; // (t/20, t, t*2, t*3)
float4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)
float4 _CosTime; // cos(t/8), cos(t/4), cos(t/2), cos(t)
float4 unity_DeltaTime; // dt, 1/dt, smoothdt, 1/smoothdt
float4 _TimeParameters; // t, sin(t), cos(t)

#if !defined(USING_STEREO_MATRICES)
float3 _WorldSpaceCameraPos;
#endif

// x = 1 or -1 (-1 if projection is flipped)
// y = near plane
// z = far plane
// w = 1/far plane
float4 _ProjectionParams;

// x = width
// y = height
// z = 1 + 1.0/width
// w = 1 + 1.0/height
float4 _ScreenParams;
float4 _ScaledScreenParams;
// x = Mip Bias
// y = 2.0 ^ [Mip Bias]
float2 _GlobalMipBias;

// Values used to linearize the Z buffer (http://www.humus.name/temp/Linearize%20depth.txt)
// x = 1-far/near
// y = far/near
// z = x/far
// w = y/far
// or in case of a reversed depth buffer (UNITY_REVERSED_Z is 1)
// x = -1+far/near
// y = 1
// z = x/far
// w = 1/far
float4 _ZBufferParams;

// x = orthographic camera's width
// y = orthographic camera's height
// z = unused
// w = 1.0 if camera is ortho, 0.0 if perspective
float4 unity_OrthoParams;

// scaleBias.x = flipSign
// scaleBias.y = scale
// scaleBias.z = bias
// scaleBias.w = unused
uniform float4 _ScaleBias;
uniform float4 _ScaleBiasRt;

float4 unity_CameraWorldClipPlanes[6];

#if !defined(USING_STEREO_MATRICES)
// Projection matrices of the camera. Note that this might be different from projection matrix
// that is set right now, e.g. while rendering shadows the matrices below are still the projection
// of original camera.
float4x4 unity_CameraProjection;
float4x4 unity_CameraInvProjection;
float4x4 unity_WorldToCamera;
float4x4 unity_CameraToWorld;
#endif

float4 _GlossyEnvironmentCubeMap_HDR;

CBUFFER_START(UnityPerDraw)
// Space block Feature
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
float4 unity_LODFade; // x is the fade value ranging within [0,1]. y is x quantized into 16 levels
float4 unity_WorldTransformParams; // w is usually 1.0, or -1.0 for odd-negative scale transforms

// Render Layer block feature
// Only the first channel (x) contains valid data and the float must be reinterpreted using asuint() to extract the original 32 bits values.
float4 unity_RenderingLayer;

// Light Indices block feature
// These are set internally by the engine upon request by RendererConfiguration.
float4 unity_LightData;
float4 unity_LightIndices[2];

float4 unity_ProbesOcclusion;

// Reflection Probe 0 block feature
// HDR environment map decode instructions
float4 unity_SpecCube0_HDR;
float4 unity_SpecCube1_HDR;

float4 unity_SpecCube0_BoxMax;          // w contains the blend distance
float4 unity_SpecCube0_BoxMin;          // w contains the lerp value
float4 unity_SpecCube0_ProbePosition;   // w is set to 1 for box projection
float4 unity_SpecCube1_BoxMax;          // w contains the blend distance
float4 unity_SpecCube1_BoxMin;          // w contains the sign of (SpecCube0.importance - SpecCube1.importance)
float4 unity_SpecCube1_ProbePosition;   // w is set to 1 for box projection

// Lightmap block feature
float4 unity_LightmapST;
float4 unity_DynamicLightmapST;
// sh
float4 unity_SHAr;
float4 unity_SHAg;
float4 unity_SHAb;
float4 unity_SHBr;
float4 unity_SHBg;
float4 unity_SHBb;
float4 unity_SHC;

// Velocity
float4x4 unity_MatrixPreviousM;
float4x4 unity_MatrixPreviousMI;
//X : Use last frame positions (right now skinned meshes are the only objects that use this
//Y : Force No Motion
//Z : Z bias value
//W : Camera only
float4 unity_MotionVectorsParams;
CBUFFER_END

//==============================
//  env paramaters ,fog
//==============================
half4 glstate_lightmodel_ambient;
half4 unity_AmbientSky;
half4 unity_AmbientEquator;
half4 unity_AmbientGround;
half4 unity_IndirectSpecColor;
float4 unity_FogParams;
half4  unity_FogColor;

#if !defined(USING_STEREO_MATRICES)
float4x4 glstate_matrix_projection;
float4x4 unity_MatrixV;
float4x4 unity_MatrixInvV;
float4x4 unity_MatrixInvP;
float4x4 unity_MatrixVP;
float4x4 unity_MatrixInvVP;
float4 unity_StereoScaleOffset;
int unity_StereoEyeIndex;
#endif

//==============================
//  Transform
//==============================

#define UNITY_MATRIX_M     unity_ObjectToWorld
#define UNITY_MATRIX_I_M   unity_WorldToObject
#define UNITY_MATRIX_V     unity_MatrixV
#define UNITY_MATRIX_I_V   unity_MatrixInvV
#define UNITY_MATRIX_P     (glstate_matrix_projection)
#define UNITY_MATRIX_I_P   unity_MatrixInvP
#define UNITY_MATRIX_VP    unity_MatrixVP
#define UNITY_MATRIX_I_VP  unity_MatrixInvVP
#define UNITY_MATRIX_MV    mul(UNITY_MATRIX_V, UNITY_MATRIX_M)
#define UNITY_MATRIX_T_MV  transpose(UNITY_MATRIX_MV)
#define UNITY_MATRIX_IT_MV transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V))
#define UNITY_MATRIX_MVP   mul(UNITY_MATRIX_VP, UNITY_MATRIX_M)
#define UNITY_PREV_MATRIX_M   unity_MatrixPreviousM
#define UNITY_PREV_MATRIX_I_M unity_MatrixPreviousMI


#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"


float3 TransformObjectToWorld(float3 objectPos){
    return mul(UNITY_MATRIX_M,float4(objectPos,1)).xyz;
}

float3 TransformObjectToView(float3 objectPos){
    return mul(UNITY_MATRIX_MV,float4(objectPos,1)).xyz;
}

float3 TransformObjectToWorldDir(float3 objectDir){
    return normalize( mul((float3x3)UNITY_MATRIX_M,objectDir) );
}

float4 TransformObjectToHClip(float3 objectPos){
    return mul(UNITY_MATRIX_VP,mul(UNITY_MATRIX_M,float4(objectPos,1)));
}

float4 TransformWorldToHClip(float3 worldPos){
    return mul(UNITY_MATRIX_VP,float4(worldPos,1));
}

float3 TransformObjectToWorldNormal(float3 normal,bool isNormalized = true){
    normal = mul(float4(normal,1),UNITY_MATRIX_I_M).xyz;
    return isNormalized ? SafeNormalize(normal) : normal;
}

float3 TransformViewToProjection(float3 viewPos){
    return mul((float3x3)UNITY_MATRIX_P,viewPos);
}
float3 GetWorldSpaceViewDir(float3 worldPos){
    return _WorldSpaceCameraPos - worldPos;
}

float3 GetWorldSpaceLightDir(float3 worldPos){
    return _MainLightPosition.xyz;// - worldPos;
}

//==============================
//  sh
//==============================


// Ref: "Efficient Evaluation of Irradiance Environment Maps" from ShaderX 2
float3 SHEvalLinearL0L1(float3 N, float4 shAr, float4 shAg, float4 shAb)
{
    float4 vA = float4(N, 1.0);

    float3 x1;
    // Linear (L1) + constant (L0) polynomial terms
    x1.r = dot(shAr, vA);
    x1.g = dot(shAg, vA);
    x1.b = dot(shAb, vA);

    return x1;
}

float3 SHEvalLinearL2(float3 N, float4 shBr, float4 shBg, float4 shBb, float4 shC)
{
    float3 x2;
    // 4 of the quadratic (L2) polynomials
    float4 vB = N.xyzz * N.yzzx;
    x2.r = dot(shBr, vB);
    x2.g = dot(shBg, vB);
    x2.b = dot(shBb, vB);

    // Final (5th) quadratic (L2) polynomial
    float vC = N.x * N.x - N.y * N.y;
    float3 x3 = shC.rgb * vC;

    return x2 + x3;
}


float3 SampleSH9(float4 SHCoefficients[7], float3 N)
{
    float4 shAr = SHCoefficients[0];
    float4 shAg = SHCoefficients[1];
    float4 shAb = SHCoefficients[2];
    float4 shBr = SHCoefficients[3];
    float4 shBg = SHCoefficients[4];
    float4 shBb = SHCoefficients[5];
    float4 shCr = SHCoefficients[6];

    // Linear + constant polynomial terms
    float3 res = SHEvalLinearL0L1(N, shAr, shAg, shAb);

    // Quadratic polynomials
    res += SHEvalLinearL2(N, shBr, shBg, shBb, shCr);

    return res;
}


// Samples SH L0, L1 and L2 terms
float3 SampleSH(float3 normalWS)
{
    // LPPV is not supported in Ligthweight Pipeline
    float4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    return max(float3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
}

//==============================
//  lightmap
//==============================
// Main lightmap
TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);

// TODO: all affine matrices should be 3x4.
// TODO: sort these vars by the frequency of use (descending), and put commonly used vars together.
// Note: please use UNITY_MATRIX_X macros instead of referencing matrix variables directly.
float4x4 _PrevViewProjMatrix;
float4x4 _ViewProjMatrix;
float4x4 _NonJitteredViewProjMatrix;
float4x4 _ViewMatrix;
float4x4 _ProjMatrix;
float4x4 _InvViewProjMatrix;
float4x4 _InvViewMatrix;
float4x4 _InvProjMatrix;
float4   _InvProjParam;
float4   _ScreenSize;       // {w, h, 1/w, 1/h}
float4   _FrustumPlanes[6]; // {(a, b, c) = N, d = -dot(N, P)} [L, R, T, B, N, F]
//==============================
//  ibl
//==============================
TEXTURECUBE(unity_SpecCube0);SAMPLER(samplerunity_SpecCube0);
TEXTURECUBE(unity_SpecCube1);SAMPLER(samplerunity_SpecCube1);
TEXTURECUBE(_GlossyEnvironmentCubeMap);SAMPLER(sampler_GlossyEnvironmentCubeMap);

#if defined(_TEST)
float3 DecodeHDREnvironment(float4 encodedIrradiance, float4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    float alpha = max(decodeInstructions.w * (encodedIrradiance.a - 1.0) + 1.0, 0.0);

    // If Linear mode is not supported we can skip exponent part
    return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * encodedIrradiance.rgb;
}
#endif

//==============================
//  lighting
//==============================
float D_GGXNoPI(float NdotH, float rough)
{
    float s = (NdotH * rough - NdotH) * NdotH + 1.0;
    return rough/ (s * s);
}


//==============================
//  Unpack from normal map , references Packing.hlsl
//==============================







#endif // UNITY_LIB_HLSL