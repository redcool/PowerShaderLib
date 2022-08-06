/**
    like UnityCG.cginc
*/

#if !defined(POWER_UTILS_HLSL)
#define POWER_UTILS_HLSL
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
// Linearize depth value sampled from the camera depth texture.
float LinearizeDepth(float z)
{
    float isOrtho = unity_OrthoParams.w;
    float isPers = 1 - unity_OrthoParams.w;
    z *= _ZBufferParams.x;
    return (1 - isOrtho * z) / (isPers * z + _ZBufferParams.y);
}

/**
screenUV -> ndc -> clip -> view
unity_MatrixInvVP
*/
float3 ScreenToWorldPos(float2 uv,float rawDepth,float4x4 invVP){
    #if defined(UNITY_UV_STARTS_AT_TOP)
        uv.y = 1-uv.y;
    #endif

    #if ! defined(UNITY_REVERSED_Z)
        rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, rawDepth);
    #endif

    float4 p = float4(uv*2-1,rawDepth,1);

    p = mul(invVP,p);
    return p.xyz/p.w;
}


#if defined(URP_LEGACY_HLSL)
    #define texCUBElod(cube,coord) cube.SampleLevel(sampler##cube,coord.xyz,coord.w)
#endif //URP_LEGACY_HLSL

#define GetWorldSpaceViewDir(worldPos) (_WorldSpaceCameraPos - worldPos)
#define GetWorldSpaceLightDir(worldPos) _MainLightPosition.xyz
#define BlendNormal(n1,n2) normalize(float3(n1.xy*n2.z+n2.xy*n1.z,n1.z+n2.z))
#define PerceptualRoughnessToMipmapLevel(roughness) roughness * (1.7 - roughness * 0.7) * 6

#endif //POWER_UTILS_HLSL