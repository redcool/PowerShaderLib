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
    #define fogHeightDensity fogDensityFalloff.x
    #define fogHeightFall fogDensityFalloff.y
    #define fogDepthDensity fogDensityFalloff.z
    #define fogDepthFall fogDensityFalloff.w
    #define depthMin fogStartDist.x
    #define depthMax fogStartDist.y
    #define heightMin fogStartDist.z

    float3 viewDir = (worldPos - viewPos);
    float viewDirDist = length(viewDir);
    // dir = mul(unity_ObjectToWorld,float4(dir,0));
    // linear depth fog
    float depthRate = (viewDirDist - depthMin)/(depthMax-depthMin);
    // depthRate = saturate(depthRate);
    // exp depth fog
    float depthFog = 1 - exp(-(viewDirDist - depthMin) * fogDepthDensity/fogDepthFall);
    // depthFog = max(0,depthFog);
    depthFog = saturate(depthFog);

    // exp height fog
    float3 centerDir = worldPos - centerPos;
    // float heightRate = (centerDir.y - fogStartDist.z)/(fogStartDist.w - fogStartDist.z);

    float heightFog = exp(- (centerDir.y - heightMin) * fogHeightDensity/fogHeightFall);
    float fog = (heightFog + depthFog)*depthRate;
    return saturate(fog);
}
#endif