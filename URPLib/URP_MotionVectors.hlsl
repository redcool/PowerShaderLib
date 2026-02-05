/**
     DrawSettings.perObjectData need MotionVector
*/
#if !defined(URP_MOTION_VECTORS_HLSL)
#define URP_MOTION_VECTORS_HLSL

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
    hClipPos.xyz *= rcp(hClipPos.w);
    lastHClipPos.xyz *= rcp(lastHClipPos.w);

    float2 velocity = hClipPos.xy - lastHClipPos.xy;
    #if UNITY_UV_STARTS_AT_TOP
        velocity.y *=-1;
    #endif
    // Convert from Clip space (-1..1) to NDC 0..1 space.
    // Note it doesn't mean we don't have negative value, we store negative or positive offset in NDC space.
    // Note: ((positionCS * 0.5 + 0.5) - (previousPositionCS * 0.5 + 0.5)) = (velocity * 0.5)    
    return float4(velocity*0.5,0,0);
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
    v2f.hClipPos = clipPos;\
*/
#define CALC_MOTION_POSITIONS(inputPrevPos,inputPos,v2f,clipPos)\
    const float4 prevPos = (unity_MotionVectorsParams.x ==1)? float4(inputPrevPos.xyz,1) : float4(inputPos.xyz,1);\
    v2f.hClipPos = mul(_NonJitteredViewProjMatrix,mul(UNITY_MATRIX_M,inputPos));\
    v2f.lastHClipPos = mul(_PrevViewProjMatrix,mul(UNITY_PREV_MATRIX_M,prevPos))\

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

#endif //URP_MOTION_VECTORS_HLSL