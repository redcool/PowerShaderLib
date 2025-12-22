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


struct AnimInfo {
    uint frameRate;
    uint startFrame;
    uint endFrame;
    float loop;
    float playTime;
    uint offsetPlayTime;
    half4 animTextureTexelSize;  // _AnimTex_TexelSize(1/w,1/h,w,h)
};

// array for debug
// #if defined(USE_ARRAY)
//     float _BoneCountPerVertex[487];
//     float _BoneStartPerVertex[487];
//     float _BoneWeights[790];
//     float _BoneIndices[790];
// #endif
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
    AnimTex
        horizontal : bones matrix per frame
        vertical : frames
    Get animation frame y position in _AnimTex

    x : per bone matrix(3 float4)
    y : animation frame
*/
float GetY(AnimInfo info) {
    // length = fps/sampleRatio
    half4 texelSize = info.animTextureTexelSize;
    float totalLen = texelSize.w / info.frameRate;
    float start = info.startFrame / texelSize.w;
    float end = info.endFrame / texelSize.w;
    float len = end - start;
    float y = start + (info.playTime + info.offsetPlayTime) / totalLen % len;
    y = lerp(y, end, info.loop);
    return y;
}

//============================================================================================ BoneTexture
#if defined(USE_BUFFER)
BoneInfoPerVertex GetBoneInfoPerVertex(uint vid){
    BoneInfoPerVertex boneInfo = _BoneInfoPerVertexBuffer[vid];
    
    // BoneInfoPerVertex boneInfo = {_BoneCountPerVertex[vid],_BoneStartPerVertex[vid]};
    return boneInfo;
}

BoneWeight1 GetBoneWeight1(float boneStart){
    BoneWeight1 bw = _BoneWeightBuffer[boneStart];
    //     BoneWeight1 bw = {_BoneWeights[boneStart],_BoneIndices[boneStart]};
    return bw;
}

/**
    BoneTexture
    Play animation ,bakeBone use this
*/
float4 GetAnimPos(uint vid,float4 pos,AnimInfo info){
    float4 bonePos = (float4)0;
    float y = GetY(info);

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
    float crossLerp = _CrossLerp;
    float4 curPos = GetAnimPos(vid,pos,info);

    info.startFrame = _NextStartFrame;
    info.endFrame = _NextEndFrame;
    float4 nextPos = GetAnimPos(vid,pos,info);

    return lerp(curPos, nextPos, crossLerp);
}
#endif // USE_BUFFER


float4 GetAnimPos(uint vid,float4 pos,AnimInfo info,float4 weights,uint4 indices){
    float4 bonePos = (float4)0;
    float y = GetY(info);

    float4x4 boneMat = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};

    UNITY_UNROLLX(4)
    for(int i=0;i<4;i++){
        float weight = weights[i];
        float boneIndex = indices[i];
        GetFloat3x4FromTexture(boneMat/**/,_AnimTex,info.animTextureTexelSize,boneIndex,y);

        bonePos += mul(boneMat,pos) * weight;
    }

    return bonePos;
}
/**
    Apply bones transform, skinnedMesh
    if pos is direction, keep w =0
*/
float4 GetBlendAnimPos(uint vid,float4 pos,float4 weights,uint4 indices) {
    AnimInfo info = GetAnimInfo();
    // SETUP_ANIM_INFO();
    float crossLerp = _CrossLerp;
    float4 curPos = GetAnimPos(vid,pos,info,weights,indices);

    info.startFrame = _NextStartFrame;
    info.endFrame = _NextEndFrame;
    float4 nextPos = GetAnimPos(vid,pos,info,weights,indices);

    return lerp(curPos, nextPos, crossLerp);
}

/**
    Apply bones transform, skinnedMesh
    Calc skinned vertex position,normal, tangent
*/
void CalcAnimPos(uint vid,inout float4 pos,inout float4 normal,inout float4 tangent,AnimInfo info,float4 weights,uint4 indices){
    float4 bonePos = (float4)0;
    float4 boneNormal =(float4)0;
    float4 boneTangent = {0,0,0,tangent.w}; // keep w
    
    float y = GetY(info);

    float4x4 boneMat = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};

    UNITY_UNROLLX(4)
    for(int i=0;i<4;i++){
        float weight = weights[i];
        float boneIndex = indices[i];
        GetFloat3x4FromTexture(boneMat/**/,_AnimTex,info.animTextureTexelSize,boneIndex,y);

        bonePos += mul(boneMat,pos) * weight;
        boneNormal += mul(boneMat,float4(normal.xyz,0)) * weight;
        boneTangent += mul(boneMat,float4(tangent.xyz,0)) * weight;
    }
    pos = bonePos;
    normal = boneNormal;
    tangent = boneTangent;
}
/**
    Apply bones transform, skinnedMesh
    CrossFade Calc skinned vertex position,normal, tangent
*/
void CalcBlendAnimPos(uint vid,inout float4 pos,inout float4 normal,inout float4 tangent,float4 weights,uint4 indices) {
    AnimInfo info = GetAnimInfo();
    // SETUP_ANIM_INFO();
    float crossLerp = _CrossLerp;
    float4 pos0 = pos,normal0=normal,tangent0=tangent;
    CalcAnimPos(vid,pos0/**/,normal0/**/,tangent0/**/,info,weights,indices);
    
    //update anim info
    info.startFrame = _NextStartFrame;
    info.endFrame = _NextEndFrame;
    float4 pos1 = pos,normal1=normal,tangent1=tangent;
    CalcAnimPos(vid,pos1/**/,normal1/**/,tangent1/**/,info,weights,indices);

    pos = lerp(pos0, pos1, crossLerp);
    normal = lerp(normal0,normal1,crossLerp);
    tangent = lerp(tangent0,tangent1,crossLerp);
}

//============================================================================================ AnimTexture
/**  
    boneMesh use this
    play animation
*/
float4 GetAnimPos(uint vertexId, AnimInfo info) {
    float y = GetY(info);
    float x = (vertexId + 0.5) * _AnimTex_TexelSize.x;

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
    
    float crossLerp = _CrossLerp;
    float4 curPos = GetAnimPos(vertexId, info);

    info.startFrame = _NextStartFrame;
    info.endFrame = _NextEndFrame;
    float4 nextPos = GetAnimPos(vertexId, info);

    return lerp(curPos, nextPos, crossLerp);
}

#endif// ANIM_TEXTURE_LIB_HLSL