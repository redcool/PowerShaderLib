#if !defined(EXP_FOG_LIB_HLSL)
#define EXP_FOG_LIB_HLSL
/**
 * Exp height and depth fog
 * 
 * @param worldPos  : fragment world pos
 * @param centerPos : heightFog start pos
 * @param viewPos  : camera world pos
 * @param fogStartDist  : {depthMin,depthMax,heightMin}
 * @param fogDensityFalloff : {fogDepthDensity,fogDepthFall,fogHeightDensity,fogHeightFall}
 * @return float : fog atten
 */
float ExpFog(float3 worldPos,float3 centerPos,float3 viewPos,float4 fogStartDist,float4 fogDensityFalloff){
    #define fogDepthDensity fogDensityFalloff.x
    #define fogDepthFall fogDensityFalloff.y
    #define fogHeightDensity fogDensityFalloff.z
    #define fogHeightFall fogDensityFalloff.w

    float3 viewDir = (worldPos - viewPos);
    float viewDirDist = length(viewDir);
    // dir = mul(unity_ObjectToWorld,float4(dir,0));
    // linear depth fog
    float depthRate = (viewDirDist - fogStartDist.x)/(fogStartDist.y - fogStartDist.x);
    // exp depth fog
    float depthFog = 1 - exp(-(viewDirDist - fogStartDist.x) * fogDepthDensity/fogDepthFall);

    // exp height fog
    float3 centerDir = worldPos - centerPos;
    // float heightRate = (centerDir.y - fogStartDist.z)/(fogStartDist.w - fogStartDist.z);

    float heightFog = exp(- (centerDir.y - fogStartDist.z) * fogHeightDensity/fogHeightFall);
    float fog = (heightFog + depthFog)*depthRate;
    return saturate(fog);
}
#endif