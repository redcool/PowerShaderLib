#if !defined(WAVE_LIB_HLSL)
#define WAVE_LIB_HLSL
/**
    waveInfo 
        xy: wave direction,
        z : wave steepness,
        w : wave length
    
*/
float3 GerstnerWave(inout float3 tangent,inout float3 binormal,float4 waveInfo,float3 worldPos,float waveScrollSpeed=1){
    float steepness = waveInfo.z;
    float waveLength = max(0.001,waveInfo.w);
    float k = 2 * PI / waveLength;
    float c = sqrt(9.8/k);
    float2 d = normalize(waveInfo.xy);
    float f = k * dot(d,worldPos.xz)  - c * _Time.y * waveScrollSpeed;
    float a = steepness/k;

    float cosF,sinF;
    sincos(f,sinF/**/,cosF/**/);

    tangent += float3(
        -d.x * d.x * steepness * sinF,
        d.x * steepness * cosF,
        -d.x * d.y * steepness * sinF
    );
    binormal += float3(
        -d.x * d.y * steepness * sinF,
        d.y * steepness * cosF,
        -d.y * d.y * steepness * sinF
    );

    return float3(
        d.x * a * cosF,
        a * sinF,
        d.y * a*cosF
    );
}

#endif //WAVE_LIB_HLSL