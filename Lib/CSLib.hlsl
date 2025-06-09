#if !defined(CS_LIB_HLSL)
#define CS_LIB_HLSL

/**
    Compute shader tools

    https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/sm5-attributes-numthreads
    https://www.jeremyong.com/graphics/2023/08/26/dispatch-ids-and-you/
*/


float3 _DispatchGroupSize; // Dispatched groups
float4 _NumThreads; // thread count in a box,(xSize,ySize,zSize,threads count)

/*
    GetDispatchThreadIndex

    groupId : SV_GroupID
    groupThreadIndex : SV_GroupIndex
    groupSize : dispatched group(box) size
    groupThreadSizeCount = thread count in a group , = (groupThreadSize.x*groupThreadSize.y*groupThreadSize.z) 
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
    Call this get dispatched thread index(like SV_DispatchThreadID)
*/
uint GetDispatchThreadIndex(uint3 groupId/*SV_GroupID*/,uint groupThreadIndex/*SV_GroupIndex*/){
    uint3 groupSize = (uint3)_DispatchGroupSize;
    uint groupThreadSizeCount = (uint)_NumThreads.w;
    return GetDispatchThreadIndex(groupId,groupThreadIndex,groupSize,groupThreadSizeCount);
}

#endif //CS_LIB_HLSL