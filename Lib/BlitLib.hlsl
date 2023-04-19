#if !defined(BLIT_LIB_HLSL)
#define BLIT_LIB_HLSL

void FullScreenTriangleVert(uint vertexId,out float4 posHClip,out float2 uv){
    posHClip = float4(
        vertexId <= 1 ? -1 : 3,
        vertexId == 1 ? 3 : -1,
        0,1
    );
    uv = float2(
        vertexId <= 1 ? 0 : 2,
        vertexId == 1 ? 2 : 0
    );
    // #if defined(UNITY_UV_STARTS_AT_TOP)
    if(_ProjectionParams.x < 0)
        uv.y = 1 - uv.y;
    // #endif
}

#endif //BLIT_LIB_HLSL