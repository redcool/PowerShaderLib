#if !defined(REFLECTION_LIB_HLSL)
#define REFLECTION_LIB_HLSL

/** Demo:
    float3 viewDirTS = WorldToTangent(viewDir,input.tSpace0,input.tSpace1,input.tSpace2);
    float3 reflectDir =(CalcInteriorMapReflectDir(viewDirTS,input.uv));
    // return reflectDir.xyzx;
    float3 iblCol= CalcIBL(reflectDir,_EnvMap,sampler_EnvMap,rough,_EnvMap_HDR);
    return float4(iblCol,1);
*/

float3 CalcInteriorMapReflectDir(float3 viewDirTS,float2 uv,float2 uvRange=float2(0,1),bool isReverseViewDir=1){
    // calc uvBounds
    uv = frac(uv);
    uv = clamp(uv,uvRange.x,uvRange.y);
    uv = uv*2-1;
    float3 uvBounds = float3(uv,1);

    viewDirTS *= -1;
    // calc corners
    float3 rcpViewDir = rcp(viewDirTS);
    rcpViewDir = abs(rcpViewDir) - rcpViewDir * uvBounds;
    float corner = min(min(rcpViewDir.x,rcpViewDir.y),rcpViewDir.z);
    viewDirTS = viewDirTS * corner + uvBounds;
    // flip back
    // viewDirTS.xy *= -1;
    
    // show cube center block directly?
    viewDirTS *= isReverseViewDir? half3(1,-1,-1) : half3(-1,-1,1);

    // viewDirTS = lerp(viewDirTS,0,uvBorder);
    return viewDirTS;
}

half3 BoxProjectedCubemapDir(half3 reflectionWS, float3 positionWS, float4 cubemapPositionWS, float4 boxMin, float4 boxMax)
{
    // Is this probe using box projection?
    if (cubemapPositionWS.w > 0.0f)
    {
        float3 boxMinMax = (reflectionWS > 0.0f) ? boxMax.xyz : boxMin.xyz;
        half3 rbMinMax = half3(boxMinMax - positionWS) / reflectionWS;

        half fa = half(min(min(rbMinMax.x, rbMinMax.y), rbMinMax.z));

        half3 worldPos = half3(positionWS - cubemapPositionWS.xyz);

        half3 result = worldPos + reflectionWS * fa;
        return result;
    }
    else
    {
        return reflectionWS;
    }
}

float3 CalcReflectDir(float3 worldPos,float3 normal,float3 viewDir,float3 reflectDirOffset=0){
    float3 reflectDir = reflect(-viewDir,normal);
    reflectDir = (reflectDir + reflectDirOffset);

    #if (SHADER_LIBRARY_VERSION_MAJOR >= 12) && defined(_REFLECTION_PROBE_BOX_PROJECTION)
    // UNITY_BRANCH if(isBoxProjection)
        reflectDir = BoxProjectedCubemapDir(reflectDir,worldPos,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
    #endif
    return reflectDir;
}

#endif //REFLECTION_LIB_HLSL