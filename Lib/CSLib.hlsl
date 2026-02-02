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

/**
    call ComputeShaderEx.Dispatchkernel

    Get dispatched thread index(SV_DispatchThreadID is 3d), like 3d array index to 1d array index
    uint dispatchThreadIndex = GetDispatchThreadIndex(groupId,dispatchThreadId);

    @param groupId : (SV_GroupID)
    @param dispatchThreadId : (SV_DispatchThreadID)
    @return dispatchThreadIndex

    formula:
        index = z * width*height+y*width+x
*/
uint GetDispatchThreadIndex(uint3 groupId/*SV_GroupID*/,uint3 dispatchThreadId/*SV_DispatchThreadID*/){
    uint3 groupSize = (uint3)_DispatchGroupSize;
    uint3 groupThreadSize = (uint3)_NumThreads.xyz * groupSize;
    return dispatchThreadId.x + dispatchThreadId.y * groupThreadSize.x + dispatchThreadId.z * groupThreadSize.x * groupThreadSize.y;
}
/**
    dp thread index to id(1d -> 3d)
    x = index % width
    y = (index/w) % height
    z = index / (width * height)

    demo:
    1 threadSize(10,10,10),index=253 ,result=(3,5,2)
    -1 remain = 53,x =53%10 = 3 ,y = 53/10=5 ,z = 2
    -2 x=253%10=3,y=253/10%10=5
    test : 2 * 10*10 + 5 * 10 + 3 = 253
*/
uint3 GetDispatchThreadId(uint index){
    uint3 groupSize = (uint3)_DispatchGroupSize;
    uint3 groupThreadSize = (uint3)_NumThreads.xyz * groupSize;
    uint width = groupThreadSize.x;
    uint area = groupThreadSize.x*groupThreadSize.y;

    uint remain = index % area;
    uint x = remain %width;
    uint y = remain /width;
    uint z = index / area;
    return uint3(x,y,z);
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