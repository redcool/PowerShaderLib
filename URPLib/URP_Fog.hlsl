#if !defined(URP_FOG_HLSL)
#define URP_FOG_HLSL
/**
    1 urp fog
    2 SIMPLE_FOG
*/

//------ SIMPLE_FOG use this
half4 _FogParams;

#if defined(_SPHERE_FOG_LAYERS)
    #include "../Lib/SphereFogLib.hlsl"
    // for SIMPLE_FOG extends
    #if defined(USE_STRUCTURED_BUFFER)
        #define _FogParams _SphereFogDatas[SPHERE_FOG_ID].fogParams
    #else
        #define _FogParams _FogParamsArray[SPHERE_FOG_ID]
    #endif
#endif

#if UNITY_REVERSED_Z
    #if SHADER_API_OPENGL || SHADER_API_GLES || SHADER_API_GLES3
        //GL with reversed z => z clip range is [near, -far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(-(coord), 0)
    #else
        //D3d with reversed Z => z clip range is [near, 0] -> remapping to [0, far]
        //max is required to protect ourselves from near plane not being correct/meaningfull in case of oblique matrices.
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(((1.0-(coord)/_ProjectionParams.y)*_ProjectionParams.z),0)
    #endif
#elif UNITY_UV_STARTS_AT_TOP
    //D3d without reversed z => z clip range is [0, far] -> nothing to do
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#else
    //Opengl => z clip range is [-near, far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#endif

#define ComputeFogFactor _ComputeFogFactor
float _ComputeFogFactor(float z)
{
    float clipZ_01 = UNITY_Z_0_FAR_FROM_CLIPSPACE(z);

    // -------------- custom linear depth fog
    #if defined(SIMPLE_FOG)
        return saturate(clipZ_01 * _FogParams.z + _FogParams.w);
    #endif

    #if defined(FOG_LINEAR)
        // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
        float fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
        return float(fogFactor);
    #elif defined(FOG_EXP) || defined(FOG_EXP2)
        // factor = exp(-(density*z)^2)
        // -density * z computed at vertex
        return float(unity_FogParams.x * clipZ_01);
    #else
        return 0.0h;
    #endif
}

#define ComputeFogIntensity _ComputeFogIntensity
float _ComputeFogIntensity(float fogFactor)
{
    float fogIntensity = 0.0h;
        #if defined(FOG_EXP)
            // factor = exp(-density*z)
            // fogFactor = density*z compute at vertex
            fogIntensity = saturate(exp2(-fogFactor));
        #elif defined(FOG_EXP2)
            // factor = exp(-(density*z)^2)
            // fogFactor = density*z compute at vertex
            fogIntensity = saturate(exp2(-fogFactor * fogFactor));
        #elif defined(FOG_LINEAR) || defined(SIMPLE_FOG)
            fogIntensity = fogFactor;
        #endif
    return fogIntensity;
}
#define MixFogColor _MixFogColor
float3 _MixFogColor(float3 fragColor, float3 fogColor, float fogFactor)
{
    float fogIntensity = ComputeFogIntensity(fogFactor);
    fragColor = lerp(fogColor, fragColor, fogIntensity);
    return fragColor;
}

#define MixFog _MixFog
float3 _MixFog(float3 fragColor, float fogFactor)
{
    return MixFogColor(fragColor, unity_FogColor.rgb, fogFactor);
}

#endif //URP_FOG_HLSL