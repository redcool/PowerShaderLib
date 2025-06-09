/**
    
*/

#if !defined(SKINNED_LIB_HLSL)
#define SKINNED_LIB_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
/** need these
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Version.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
*/

struct BoneInfoPerVertex{
    uint bonesCount;
    uint bonesStartIndex;
};
struct BoneWeight1{
    float weight;
    uint boneIndex;
};

StructuredBuffer<BoneInfoPerVertex> _BoneInfoPerVertexBuffer;
StructuredBuffer<BoneWeight1> _BoneWeightBuffer;
RWStructuredBuffer<float4x4> _Bones;

/**
    Get vertex skinned local position from _Bones sbuffer
    vid : vertexId
    pos : vertex local position
*/
float4 GetSkinnedPos(uint vid,float4 pos){
    float4 bonePos = (float4)0;

    BoneInfoPerVertex boneInfo = _BoneInfoPerVertexBuffer[vid];
    float bonesCount = boneInfo.bonesCount;
    float boneStart = boneInfo.bonesStartIndex;

    float4x4 boneMat = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};

    UNITY_UNROLLX(4)
    for(int i=0;i<bonesCount;i++){
        BoneWeight1 bw = _BoneWeightBuffer[boneStart + i];
        float weight = bw.weight;
        uint boneIndex = bw.boneIndex;

        boneMat = _Bones[boneIndex];
        bonePos += mul(boneMat,pos) * weight;
    }

    return bonePos;
}

/**
    Get float3x4 from boneTex(a bone matrix = 3 x float4)
*/
void GetFloat3x4FromTexture(inout float4x4 boneMat,sampler2D boneTex,float4 pixelSize,float boneIndex,float y){
    float x = (boneIndex*3+0.5) * pixelSize.x;
    boneMat[0] = tex2Dlod(boneTex,float4(x,y,0,0));
    boneMat[1] = tex2Dlod(boneTex,float4(x + pixelSize.x,y,0,0));
    boneMat[2] = tex2Dlod(boneTex,float4(x + pixelSize.x * 2,y,0,0));
}

#endif //SKINNED_LIB_HLSL