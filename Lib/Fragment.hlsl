/**
    need include PowerUtils.hlsl
**/
#if !defined(FRAGMENT_HLSL)
#define FRAGMENT_HLSL

struct Fragment{
    float2 screenPos;
    float2 screenUV;
    float depth;
};

Fragment GetFragment(float4 posHClip){
    Fragment f = (Fragment)0;
    f.screenPos = posHClip.xy;
    f.screenUV = f.screenPos/_ScreenParams.xy;
    // f.depth = IsOrthographicCamera()? OrthographicDepthBufferToLinear(posHClip.z) : LinearEyeDepth(posHClip.w,_ZBufferParams);
    f.depth = CalcLinearEyeDepth(posHClip);
    return f;
}

#endif //FRAGMENT_HLSL