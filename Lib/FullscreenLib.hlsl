/**
    MATERIAL_VARIABLES : skip material variables define

*/

#if !defined(FULLSCREEN_LIB_HLSL)
#define FULLSCREEN_LIB_HLSL


#if !defined(MATERIAL_VARIABLES)
// half _FullScreenOn; // output to full rt
float4 _FullScreenUVRange; // output rect,default (0,0,1,1)
half _FullScreenUVId; // material use uv id when bake
#endif

/**
    remap ndc[-1,1] to new screen pos,default [0,0,1,1]
*/
float2 RemapNdcToScreenPos(float2 ndcPos/*[-1,1]*/,float4 screenPosRange/*[0,1]*/){
    float4 range = screenPosRange * 2- 1;// xz:x range,yw:y range
    float2 ndc01 = ndcPos * 0.5 + 0.5;
    return lerp(range.xy,range.zw,ndc01);
}

/**
    Transform object to ndc[-1,1] or hclip
    screenPosRange : default [0,0,1,1]
*/
float4 TransformObjectToNdcHClip(float4 vertex,bool isNdc,float4 screenPosRange,bool isUseUV1=false,float2 uv1=0){
    float2 suv = isUseUV1 ? uv1 - 0.5: vertex.xy;
    float4 ndcPos = float4(suv*2,UNITY_NEAR_CLIP_VALUE,1); // [-0.5,0.5] ,like unity cube ,quad
    ndcPos.xy = RemapNdcToScreenPos(ndcPos.xy,screenPosRange) ;
    return isNdc ? ndcPos : TransformObjectToHClip(vertex.xyz);
}
#endif //FULLSCREEN_LIB_HLSL