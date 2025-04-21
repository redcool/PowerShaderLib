/**
     DrawSettings.perObjectData need MotionVector
*/
#if !defined(URP_MOTION_VECTORS_HLSL)
#define URP_MOTION_VECTORS_HLSL

#include "../Lib/DepthLib.hlsl"
sampler2D _MotionVectorTexture;
/**
    output fragment's velocity
*/
float4 CalcMotionVectors(float4 hClipPos,float4 lastHClipPos){
    // Note: unity_MotionVectorsParams.y is 0 is forceNoMotion is enabled
    bool forceNoMotion = unity_MotionVectorsParams.y == 0.0;
    if (forceNoMotion)
    {
        return half4(0.0, 0.0, 0.0, 0.0);
    }
    hClipPos.xyz /= hClipPos.w;
    lastHClipPos.xyz /= lastHClipPos.w;

    float2 velocity = hClipPos.xy - lastHClipPos.xy;
    #if UNITY_UV_STARTS_AT_TOP
        velocity.y *=-1;
    #endif
    // Convert from Clip space (-1..1) to NDC 0..1 space.
    // Note it doesn't mean we don't have negative value, we store negative or positive offset in NDC space.
    // Note: ((positionCS * 0.5 + 0.5) - (previousPositionCS * 0.5 + 0.5)) = (velocity * 0.5)    
    return float4(velocity*0.5,0,0);
}

float4 CalcMotionVectors(float4 hClipPos,float2 suv){
    // Note: unity_MotionVectorsParams.y is 0 is forceNoMotion is enabled
    bool forceNoMotion = unity_MotionVectorsParams.y == 0.0;
    if (forceNoMotion)
    {
        return half4(0.0, 0.0, 0.0, 0.0);
    }
    hClipPos.xyz /= hClipPos.w;

    float4 lastHClipPos = tex2D(_MotionVectorTexture,suv);

    float2 velocity = hClipPos.xy - lastHClipPos.zw;
    #if UNITY_UV_STARTS_AT_TOP
        velocity.y *=-1;
    #endif

    return float4(velocity*0.5,hClipPos.xy);
}

/***
    1 declare in vertex's Attribute(appdata)
    varName : variable's name
*/
#define DECLARE_MOTION_VS_INPUT(varName) float4 varName:TEXCOORD4

/**
    2 declare in vs output struct (v2f)
    id0 : texcoord X
    id1 : texcoord Y
*/
#define DECLARE_MOTION_VS_OUTPUT(id0,id1)\
    float4 lastHClipPos:TEXCOORD##id0;\
    float4 hClipPos:TEXCOORD##id1

/**
    3call  in vertex shader

    inputPos : vs's input , previous position
    inputPrevPos : vs input, current position
    output : v2f
    clipPos : homogeneous clip space position
*/ 
#define CALC_MOTION_POSITIONS(inputPrevPos,inputPos,v2f,clipPos)\
    const float4 prevPos = (unity_MotionVectorsParams.x ==1)? float4(inputPrevPos.xyz,1) : float4(inputPos.xyz,1);\
    v2f.hClipPos = clipPos;\
    v2f.lastHClipPos = mul(_PrevViewProjMatrix,mul(UNITY_PREV_MATRIX_M,prevPos))\

/*
    Optimise CALC_MOTION_POSITIONS
    Transform worldPos to prevVP

    inputPrevPos : last vertex position
    inputPos : current world position
    v2f : current v2f struct
    clipPos : current hclip position
*/
#define CALC_MOTION_POSITIONS_WORLD(inputPrevPos,inputPos,v2f,clipPos)\
    v2f.hClipPos = clipPos;\
    v2f.lastHClipPos = mul(_PrevViewProjMatrix,float4(inputPos,1))\

#define ZERO_MOTION_POSITIONS(inputPrevPos,inputPos,v2f,clipPos)\
    v2f.hClipPos = clipPos;\
    v2f.lastHClipPos = clipPos;\

/**
    4 call in frag function
    return float4(xy:motion vectors,zw:(01))

    like :
    float4 outputMotionVectors = CALC_MOTION_VECTORS(v2f); //CalcMotionVectors(input.hClipPos,input.lastHClipPos);
    
*/
#define CALC_MOTION_VECTORS(v2f) CalcMotionVectors(v2f.hClipPos,v2f.lastHClipPos)
#define CALC_MOTION_VECTORS2(v2f,suv) CalcMotionVectors(v2f.hClipPos,suv)

#endif //URP_MOTION_VECTORS_HLSL