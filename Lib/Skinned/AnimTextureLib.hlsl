/**
    1 
    first define SETUP_ANIM_INFO(variables) then include this
    demo see :
        AnimTexture.shader
        BoneTexture.shader

    2
    anim data sample from _AnimTex,
    can redefine _AnimTex when use other texture.
    
    3 version
    BoneTexture : with pos
    AnimTexture : no pos
*/

#if !defined(ANIM_TEXTURE_LIB_HLSL)
#define ANIM_TEXTURE_LIB_HLSL
#include "SkinnedLib.hlsl"

sampler2D _AnimTex;

#define USE_BUFFER
#if !defined(USE_BUFFER)
// CBUFFER_START(AnimTexture)
    float _BoneCountPerVertex[487];
    float _BoneStartPerVertex[487];
    float _BoneWeights[790];
    float _BoneIndices[790];
// CBUFFER_END
#endif

struct AnimInfo {
    uint frameRate;
    uint startFrame;
    uint endFrame;
    half loop;
    half playTime;
    uint offsetPlayTime;
    half4 animTextureTexelSize;  // _AnimTex_TexelSize(1/w,1/h,w,h)
};

/**
    setup a animInfo
*/
// #define SETUP_ANIM_INFO()\
//     AnimInfo info =(AnimInfo)0;\
//     info.frameRate = _AnimSampleRate;\
//     info.startFrame = _StartFrame;\
//     info.endFrame = _EndFrame;\
//     info.loop = _Loop;\
//     info.playTime = _PlayTime;\
//     info.animTextureTexelSize = _AnimTex_TexelSize;\
//     info.offsetPlayTime = _OffsetPlayTime

AnimInfo GetAnimInfo(){
    AnimInfo info =(AnimInfo)0;

    info.frameRate = _AnimSampleRate;
    info.startFrame = _StartFrame;
    info.endFrame = _EndFrame;
    info.loop = _Loop;
    info.playTime = _PlayTime;
    info.offsetPlayTime = _OffsetPlayTime;
    info.animTextureTexelSize = _AnimTex_TexelSize;
    return info;
}

/**
    Get animation frame y position in _AnimTex

    x : per bone matrix(3 float4)
    y : animation frames
*/
half GetY(AnimInfo info) {
    // length = fps/sampleRatio
    half4 texelSize = info.animTextureTexelSize;
    half totalLen = texelSize.w / info.frameRate;
    half start = info.startFrame / texelSize.w;
    half end = info.endFrame / texelSize.w;
    half len = end - start;
    half y = start + (info.playTime + info.offsetPlayTime) / totalLen % len;
    y = lerp(y, end, info.loop);
    return y;
}

//============================================================================================ BoneTexture
BoneInfoPerVertex GetBoneInfoPerVertex(uint vid){
    #if defined(USE_BUFFER)
    BoneInfoPerVertex boneInfo = _BoneInfoPerVertexBuffer[vid];
    #else
    BoneInfoPerVertex boneInfo = {_BoneCountPerVertex[vid],_BoneStartPerVertex[vid]};
    #endif
    return boneInfo;
}

BoneWeight1 GetBoneWeight1(float boneStart){
    #if defined(USE_BUFFER)
        BoneWeight1 bw = _BoneWeightBuffer[boneStart];
    #else
        BoneWeight1 bw = {_BoneWeights[boneStart],_BoneIndices[boneStart]};
    #endif
    return bw;
}

/**
    BoneTexture
    Play animation ,bakeBone use this
*/
float4 GetAnimPos(uint vid,float4 pos,AnimInfo info){
    float4 bonePos = (float4)0;
    half y = GetY(info);

    BoneInfoPerVertex boneInfo = GetBoneInfoPerVertex(vid);
    float bonesCount = boneInfo.bonesCount;
    float boneStart = boneInfo.bonesStartIndex;

    float4x4 boneMat = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};

    UNITY_UNROLLX(4)
    for(int i=0;i<bonesCount;i++){
        BoneWeight1 bw = GetBoneWeight1(boneStart+i);
        float weight = bw.weight;
        float boneIndex = bw.boneIndex;
        GetFloat3x4FromTexture(boneMat/**/,_AnimTex,info.animTextureTexelSize,boneIndex,y);

        bonePos += mul(boneMat,pos) * weight;
    }

    return bonePos;
}
/**
    BoneTexture
    Play animation ,bakeBone use this
*/
float4 GetAnimPos(uint vid,float4 pos){
    AnimInfo info = GetAnimInfo();
    // SETUP_ANIM_INFO();
    return GetAnimPos(vid,pos,info);
}

/**
    AnimTexture
    crossFade play animation
*/
float4 GetBlendAnimPos(uint vid,float4 pos) {
    AnimInfo info = GetAnimInfo();
    // SETUP_ANIM_INFO();
    half crossLerp = _CrossLerp;
    float4 curPos = GetAnimPos(vid,pos,info);

    info.startFrame = _NextStartFrame;
    info.endFrame = _NextEndFrame;
    float4 nextPos = GetAnimPos(vid,pos,info);

    return lerp(curPos, nextPos, crossLerp);
}
//============================================================================================ AnimTexture
/**  
    boneMesh use this
    play animation
*/
float4 GetAnimPos(uint vertexId, AnimInfo info) {
    half y = GetY(info);
    half x = (vertexId + 0.5) * _AnimTex_TexelSize.x;

    float4 animPos = tex2Dlod(_AnimTex, half4(x, y, 0, 0));
    return animPos;
}
/**
    boneMesh use
    play animation
*/
float4 GetAnimPos(uint vertexId){
    AnimInfo info = GetAnimInfo();
    return GetAnimPos(vertexId,info);
}
/**
    boneMesh use
    cross fade play animation
*/
float4 GetBlendAnimPos(uint vertexId) {
    AnimInfo info = GetAnimInfo();
    // SETUP_ANIM_INFO();
    
    half crossLerp = _CrossLerp;
    float4 curPos = GetAnimPos(vertexId, info);

    info.startFrame = _NextStartFrame;
    info.endFrame = _NextEndFrame;
    float4 nextPos = GetAnimPos(vertexId, info);

    return lerp(curPos, nextPos, crossLerp);
}

#endif// ANIM_TEXTURE_LIB_HLSL