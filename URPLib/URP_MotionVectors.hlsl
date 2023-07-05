#if !defined(URP_MOTION_VECTORS_HLSL)
#define URP_MOTION_VECTORS_HLSL

/**
    output fragment's velocity
*/
float4 CalcMotionVectors(float4 hClipPos,float4 lastHClipPos){
    hClipPos.xyz /= hClipPos.w;
    lastHClipPos.xyz /= lastHClipPos.w;

    float2 velocity = hClipPos.xy - lastHClipPos.xy;
    #if UNITY_UV_STARTS_AT_TOP
        velocity.y *=-1;
    #endif
    // Convert from Clip space (-1..1) to NDC 0..1 space.
    // Note it doesn't mean we don't have negative value, we store negative or positive offset in NDC space.
    // Note: ((positionCS * 0.5 + 0.5) - (previousPositionCS * 0.5 + 0.5)) = (velocity * 0.5)    
    return float4(velocity*0.5,0,1);
}

/***
    1 declare in vertex's Attribute(appdata)
*/
#define DECLARE_MOTION_VS_INPUT(varName) float3 varName:TEXCOORD4

/**
    2 declare in vs output struct (v2f)
*/
#define DECLARE_MOTION_VS_OUTPUT(id0,id1)\
    float4 lastHClipPos:TEXCOORD##id0;\
    float4 hClipPos:TEXCOORD##id1

/**
    3 call CALC_MOTION_VECTORS in frag function
    return float4(xy:motion vectors,zw:(01))

    like :
    float4 outputMotionVectors = CALC_MOTION_VECTORS(v2f); //CalcMotionVectors(input.hClipPos,input.lastHClipPos);
    
*/
#define CALC_MOTION_VECTORS(v2f) CalcMotionVectors(v2f.hClipPos,v2f.lastHClipPos)

#endif //URP_MOTION_VECTORS_HLSL