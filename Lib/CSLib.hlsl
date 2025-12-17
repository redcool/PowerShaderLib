#if !defined(CS_LIB_HLSL)
#define CS_LIB_HLSL
#include "./UnityLib.hlsl"
#if ! defined(POINT_LINEAR_SAMPLER)
    SamplerState sampler_point_clamp,sampler_linear_clamp;
#endif
/**
    Compute shader tools

    https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/sm5-attributes-numthreads
    https://www.jeremyong.com/graphics/2023/08/26/dispatch-ids-and-you/
*/

/**
    ComputeShaderEx.Dispatchkernel, will set these vars
*/
float3 _DispatchGroupSize; // Dispatched groups
float4 _NumThreads; // thread count in a box,(xSize,ySize,zSize,threads count)

/*
    ComputeShaderEx.Dispatchkernel

    GetDispatchThreadIndex, 
        for 1 dimension buffer( 1d array)
        2d is SWTexture, use SV_DispatchThreadID

    groupId : SV_GroupID
    groupThreadIndex : SV_GroupIndex
    groupSize : dispatched group(box) size
    groupThreadSizeCount = thread count in a group , = (groupThreadSize.x*groupThreadSize.y*groupThreadSize.z) 

demo:
[numthreads(8,8,1)]
void CalcTest (uint3 id : SV_DispatchThreadID,uint3 groupId : SV_GROUPID,uint groupThreadIndex:SV_GROUPINDEX)
{
    uint dispatchThreadIndex = GetDispatchThreadIndex(groupId,groupThreadIndex);
    // dispatchThreadIndex is sbuffer index
}
*/
uint GetDispatchThreadIndex(uint3 groupId/*SV_GroupID*/,uint groupThreadIndex/*SV_GroupIndex*/,uint3 groupSize/*Dispatched groups*/,uint groupThreadSizeCount/*thread count a groups*/){
    //SV_GroupId(2,1,0) = 0*5*3+1*5+2 = 7
    uint groupIndex = groupId.z * groupSize.x * groupSize.y + groupId.y * groupSize.x + groupId.x;;
    return (groupIndex-1) * groupThreadSizeCount + groupThreadIndex;
}

// uint GetDispatchThreadIndex(uint3 groupId/*SV_GroupID*/,uint groupThreadIndex/*SV_GroupIndex*/,uint3 groupSize/*Dispatched groups*/,uint3 groupThreadSize/*thread size a groups*/){
//     //SV_GroupId(2,1,0) = 0*5*3+1*5+2 = 7
//     uint groupIndex = groupId.z * groupSize.x * groupSize.y + groupId.y * groupSize.x + groupId.x;;
//     return (groupIndex-1) * (groupThreadSize.x*groupThreadSize.y*groupThreadSize.z) + groupThreadIndex;
// }

/**
    csharp ComputeShaderEx.Dispatchkernel

    Get dispatched thread index(SV_DispatchThreadID is 3d), like 3d array index to 1d array index
    uint dispatchThreadIndex = GetDispatchThreadIndex(groupId,groupThreadIndex);

    @param groupId : (SV_GroupID)
    @param groupThreadIndex : (SV_GroupIndex)
    @return dispatchThreadIndex

*/
uint GetDispatchThreadIndex(uint3 groupId/*SV_GroupID*/,uint groupThreadIndex/*SV_GroupIndex*/){
    uint3 groupSize = (uint3)_DispatchGroupSize;
    uint groupThreadSizeCount = (uint)_NumThreads.w;
    return GetDispatchThreadIndex(groupId,groupThreadIndex,groupSize,groupThreadSizeCount);
}

/**
    id.xy(pixel coords) -> uv[0,1]

    id : SV_DispatchThreadID
    tex : Texture2D
    texSize : (width,height,1/width,1/height)
*/
float2 GetUV(uint3 id,TEXTURE2D(tex),float4 texelSize){
    #if defined(MIP_COUNT_SUPPORTED) // defined  core/Common.hlsl
        uint mipLevel=0, width=0, height=0, mipCount=0;
        tex.GetDimensions(mipLevel, width, height, mipCount);
        return id.xy/float2(width,height);
    #endif
    return id.xy * texelSize.zw;
}
/**
    id.xy(pixel coords) -> uv[0,1]

    id : SV_DispatchThreadID
    tex : RWTexture2D , renderTexture(uav)
    texSize : (width,height,1/width,1/height)
*/
float2 GetUV(uint3 id,RWTexture2D<float4> tex,float4 texelSize){
    #if defined(MIP_COUNT_SUPPORTED) // defined  core/Common.hlsl
        uint width=0, height=0;
        tex.GetDimensions(width, height);
        return id.xy/float2(width,height);
    #endif
    return id.xy * texelSize.zw;
}
#endif //CS_LIB_HLSL