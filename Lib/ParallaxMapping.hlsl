#if !defined(POM_HLSL)
#define POM_HLSL

// #undef TANGENT_SPACE_ROTATION
// #define TANGENT_SPACE_ROTATION(input)\
//     half3 b = normalize(cross(input.normal,input.tangent.xyz)) * input.tangent.w;\
//     half3x3 rotation = half3x3(input.tangent.xyz,b,input.normal)

/**
    heightScale : material parameter
    viewTS : tangent space view dir
    height : base height in map
*/
float2 ParallaxMapOffset(float heightScale,half3 viewTS,float height){
    return (height-0.5)* heightScale * viewTS.xy * 0.5;
}


/** POM
    demo:
    input.uv.xy += ParallaxOcclusionOffset(_ParallaxHeight,input.viewDirTS_NV.xyz,0.5,input.uv.xy,_ParallaxMap,sampler_ParallaxMap,10,100);

    define USE_SAMPLER2D,if use sampler2D
*/
#if defined(USE_SAMPLER2D)
    #define TEXTURE2D_PARAM(textureName, samplerName)  sampler2D textureName
#endif

half2 ParallaxOcclusionOffset(float heightScale,half3 viewTS,float sampleRatio,half2 uv,TEXTURE2D_PARAM(heightMap,heightMapSampler),int minCount,int maxCount){
    float parallaxLimit = -length(viewTS.xy)/viewTS.z;
    parallaxLimit *= heightScale;

    half2 offsetDir = normalize(viewTS.xy);
    half2 maxOffset = offsetDir * parallaxLimit;

    int numSamples = (int)lerp(minCount,maxCount,saturate(sampleRatio));
    float stepSize = 1.0/numSamples;

    half2 dx = ddx(uv);
    half2 dy = ddy(uv);

    half2 curOffset = 0;
    half2 lastOffset = 0;

    float curRayHeight = 1;
    float curHeight=1,lastHeight = 1;

    int curSample = 0;
    while(curSample < numSamples){
        float2 curUV = saturate(uv + curOffset);
        #if defined(USE_SAMPLER2D)
        curHeight = tex2Dgrad(heightMap,curUV,dx,dy).x;
        #else
        half4 tex = SAMPLE_TEXTURE2D_GRAD(heightMap,heightMapSampler,curUV,dx,dy);
        curHeight = tex.x;
        #endif

        if( curHeight > curRayHeight){
            float delta1 = curHeight - curRayHeight;
            float delta2 = (curRayHeight + stepSize) - lastHeight;

            float ratio = delta1 /(delta1 + delta2);

            curOffset = lerp(curOffset,lastOffset,ratio);
            curSample = numSamples + 1;
        }else{
            curSample ++;
            curRayHeight -= stepSize;

            lastOffset = curOffset;
            curOffset += stepSize * maxOffset;

            lastHeight = curHeight;
        }
    }
    return curOffset;
}

#endif //POM_HLSL