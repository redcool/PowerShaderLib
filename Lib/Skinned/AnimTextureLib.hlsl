/**
1 define _ANIMTEX_TEXELSIZE

*/

#if !defined(ANIM_TEXTURE_LIB_HLSL)
#define ANIM_TEXTURE_LIB_HLSL

#if !defined(_ANIMTEX_TEXELSIZE)
    #define _ANIMTEX_TEXELSIZE float4(0,0,1,1)
#endif

#define USE_BUFFER

#include "SkinnedLib.hlsl"

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
};

/**
    setup a animInfo
*/
#define SETUP_ANIM_INFO()\
    AnimInfo info =(AnimInfo)0;\
    info.frameRate = _AnimSampleRate;\
    info.startFrame = _StartFrame;\
    info.endFrame = _EndFrame;\
    info.loop = _Loop;\
    info.playTime = _PlayTime;\
    info.offsetPlayTime = _OffsetPlayTime

/**
    Get animation frame y position in _AnimTex

    1 _ANIMTEX_TEXELSIZE : _AnimTex_TexelSize(1/w,1/h,w,h)

    x : per bone matrix(3 float4)
    y : animation frames
*/
half GetY(AnimInfo info) {
    // length = fps/sampleRatio
    half totalLen = _ANIMTEX_TEXELSIZE.w / info.frameRate;
    half start = info.startFrame / _ANIMTEX_TEXELSIZE.w;
    half end = info.endFrame / _ANIMTEX_TEXELSIZE.w;
    half len = end - start;
    half y = start + (info.playTime + info.offsetPlayTime) / totalLen % len;
    y = lerp(y, end, info.loop);
    return y;
}


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
    Play animation 
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
        GetFloat3x4FromTexture(boneMat/**/,_AnimTex,_ANIMTEX_TEXELSIZE,boneIndex,y);

        bonePos += mul(boneMat,pos) * weight;
    }

    return bonePos;
}
/**
    Play animation 
*/
float4 GetAnimPos(uint vid,float4 pos){
    // AnimInfo info = GetAnimInfo();
    SETUP_ANIM_INFO();
    return GetAnimPos(vid,pos,info);
}

/**
play animation with crossFade
*/
float4 GetBlendAnimPos(uint vid,float4 pos) {
    // AnimInfo info = GetAnimInfo();
    SETUP_ANIM_INFO();
    half crossLerp = _CrossLerp;
    float4 curPos = GetAnimPos(vid,pos,info);

    info.startFrame = _NextStartFrame;
    info.endFrame = _NextEndFrame;
    float4 nextPos = GetAnimPos(vid,pos,info);

    return lerp(curPos, nextPos, crossLerp);
}

#endif// ANIM_TEXTURE_LIB_HLSL