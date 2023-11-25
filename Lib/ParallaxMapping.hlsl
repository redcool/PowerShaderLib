#if !defined(POM_HLSL)
#define POM_HLSL

// #undef TANGENT_SPACE_ROTATION
// #define TANGENT_SPACE_ROTATION(input)\
//     half3 b = normalize(cross(input.normal,input.tangent.xyz)) * input.tangent.w;\
//     half3x3 rotation = half3x3(input.tangent.xyz,b,input.normal)

/** PM
    heightScale : material parameter
    viewTS : tangent space view dir
    height : base height in map
*/
float2 ParallaxMapOffset(float heightScale,half3 viewTS,float height){
    return (height-0.5)* heightScale * viewTS.xy * 0.5;
}


/** POM

    demo:
    uv += ParallaxOcclusionOffset(_ParallaxHeight,input.viewDirTS_NV.xyz,0.5,input.uv.xy,_ParallaxMap,sampler_ParallaxMap,10,100);
    //---------
    tex2D
    #define USE_SAMPLER2D,if use sampler2D
    ParallaxOcclusionOffset(_ParallaxHeight,input.viewDirTS_NV.xyz,0.5,input.uv.xy,_ParallaxMap,,10,100);
    //---------
    clamp uv
    if(uv.x >1 || uv.x < 0 || uv.y>1 ||uv.y<0)
        discard; // uv = 0
*/
#if defined(USE_SAMPLER2D)
    #define TEXTURE2D_PARAM(textureName, samplerName)  sampler2D textureName
    #define SAMPLE_DEPTH_TEX(depthTex,depthTexSampler,uv) tex2D(depthTex,uv)
#else
    #define SAMPLE_DEPTH_TEX(depthTex,depthTexSampler,uv) SAMPLE_TEXTURE2D(depthTex,depthTexSampler,uv)
#endif

//half2 ParallaxOcclusionOffset(float heightScale,half3 viewTS,float sampleRatio,half2 uv,TEXTURE2D_PARAM(heightMap,heightMapSampler),)
float2 ParallaxOcclusionOffset(float heightScale,float3 viewDirTS,float2 uv,TEXTURE2D_PARAM(depthTex,depthTexSampler),half2 layerRange=(8,30)){
    float numLayers = lerp(layerRange.y,layerRange.x,abs(dot(half3(0,0,1),viewDirTS)));
    // const float numLayers = 10;
    float layerDepth = 1/numLayers;
    float curLayerDepth = 0.0;
    float2 P = viewDirTS.xy * heightScale;
    float2 deltaUV = P/numLayers;
    float2 curUV = uv;

    float curDepth = SAMPLE_DEPTH_TEX(depthTex,depthTexSampler,curUV).x;
    UNITY_LOOP while(curLayerDepth < curDepth){
        curUV -= deltaUV;
        curDepth = SAMPLE_DEPTH_TEX(depthTex,depthTexSampler,curUV).x;
        curLayerDepth += layerDepth;
    }
    // return curUV - uv; // steep end

    // ------- occlusion offset
    float2 prevUV = curUV + deltaUV;
    float afterDepth = curDepth - curLayerDepth;
    float beforeDepth = SAMPLE_DEPTH_TEX(depthTex,depthTexSampler,prevUV).x - curLayerDepth + layerDepth;
    float weight = afterDepth/(afterDepth - beforeDepth);
    float2 finalUV = lerp(curUV,prevUV,weight);
    return finalUV - uv;
}
#endif //POM_HLSL