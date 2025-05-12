#if !defined(BLIT_LIB_HLSL)
#define BLIT_LIB_HLSL
/**
    Fullscreen triangle
    use CommandBufferEx.BlitTriangle
*/
void FullScreenTriangleVert(uint vertexId,out float4 posHClip,out float2 uv,float z = UNITY_NEAR_CLIP_VALUE){
    // posHClip = float4(
    //     vertexId <= 1 ? -1 : 3,
    //     vertexId == 1 ? 3 : -1,
    //     z,
    //     1
    // );

    // uv = float2(
    //     vertexId <= 1 ? 0 : 2,
    //     vertexId == 1 ? 2 : 0
    // );

    uv = float2((vertexId << 1) & 2, vertexId & 2);
    posHClip = float4(uv * 2.0 - 1.0, z, 1.0);

    // #if defined(UNITY_UV_STARTS_AT_TOP)
    if(_ProjectionParams.x < 0)
        uv.y = 1 - uv.y;
    // #endif
}

/**
    use CommandBuffer.Blit
*/
void FullScreenQuadUnityBlit(float4 vertex,out float4 posHClip,out float2 uv){
    posHClip = float4(vertex.xy*2-1,UNITY_NEAR_CLIP_VALUE,1);
    uv = vertex.xy;
}

#endif //BLIT_LIB_HLSL