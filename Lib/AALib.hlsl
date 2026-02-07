#if !defined(AA_LIB_HLSL)
#define AA_LIB_HLSL

#include "MathLib.hlsl"

/**
    Find edge by color luma
*/
float CalcEdgeLuma(TEXTURE2D_PARAM(tex,texSampler),float2 uv,float4 texelSize,float edgeThreshold,half texelSizeScale=1.5){
    float2 delta = texelSize.xy * texelSizeScale;
    
    float4 c0 = SAMPLE_TEXTURE2D(tex,texSampler,uv);
    float4 c1 = SAMPLE_TEXTURE2D(tex,texSampler,uv - float2(delta.x,0));
    float4 c2 = SAMPLE_TEXTURE2D(tex,texSampler,uv + float2(delta.x,0));
    float4 c3 = SAMPLE_TEXTURE2D(tex,texSampler,uv - float2(0,delta.y));
    float4 c4 = SAMPLE_TEXTURE2D(tex,texSampler,uv + float2(0,delta.y));

    float a = GetLuma(c0);
    float b = GetLuma(c1);
    float c = GetLuma(c2);
    float d = GetLuma(c3);
    float e = GetLuma(c4);

    float maxLuma = Max5(a,b,c,d,e);
    float minLuma = Min5(a,b,c,d,e);
    half isEdge = (maxLuma - minLuma) > edgeThreshold;
    return isEdge;
}


#endif //AA_LIB_HLSL