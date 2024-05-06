#if! defined(FLOW_MAP_HLSL)
#define FLOW_MAP_HLSL

/**
    Get flowDir from flowMap
    xy : flowDir
    zw : flowMap.zw
*/
float4 CalcFlowDir(sampler2D flowMap,float2 uv,float2 uvScale,float2 uvOffset,
    float2 flowDirScale,float2 flowDirOffset
){
    float4 flowDir = tex2D(flowMap,uv * uvScale + uvOffset*_Time.yy);
    flowDir.xy = (flowDir.xy * 2 - 1) * flowDirScale + flowDirOffset * _Time.yy;
    return flowDir;
}

#endif //FLOW_MAP_HLSL