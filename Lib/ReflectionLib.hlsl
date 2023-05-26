#if !defined(REFLECTION_LIB_HLSL)
#define REFLECTION_LIB_HLSL

/** Demo:
    float3 viewDirTS = WorldToTangent(viewDir,input.tSpace0,input.tSpace1,input.tSpace2);
    float3 reflectDir =(CalcInteriorMapReflectDir(viewDirTS,input.uv));
    // return reflectDir.xyzx;
    float3 iblCol= CalcIBL(reflectDir,_EnvMap,sampler_EnvMap,rough,_EnvMap_HDR);
    return float4(iblCol,1);
*/

float3 CalcInteriorMapReflectDir(float3 viewDirTS,float2 uv){
    // calc uvBounds
    uv = frac(uv)*2-1;
    float3 uvBounds = float3(uv,1);

    viewDirTS *= -1;
    // calc corners
    float3 rcpViewDir = rcp(viewDirTS);
    rcpViewDir = abs(rcpViewDir) - rcpViewDir * uvBounds;
    float corner = min(min(rcpViewDir.x,rcpViewDir.y),rcpViewDir.z);
    viewDirTS = viewDirTS * corner + uvBounds;
    // flip back
    viewDirTS.xy *= -1;
    return viewDirTS;
}

float3 CalcReflectDir(float3 worldPos,float3 normal,float3 viewDir,float3 reflectDirOffset=0){
    float3 reflectDir = reflect(-viewDir,normal);
    reflectDir = (reflectDir + reflectDirOffset);

    #if (SHADER_LIBRARY_VERSION_MAJOR >= 12) && defined(_REFLECTION_PROBE_BOX_PROJECTION)
    reflectDir = BoxProjectedCubemapDirection(reflectDir,worldPos,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
    #endif
    return reflectDir;
}

#endif //REFLECTION_LIB_HLSL