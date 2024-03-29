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

    tangent += float3(
        -d.x * d.x * steepness * sin(f),
        d.x * steepness * cos(f),
        -d.x * d.y * steepness * sin(f)
    );
    binormal += float3(
        -d.x * d.y * steepness * sin(f),
        d.y * steepness * cos(f),
        -d.y * d.y * steepness * sin(f)
    );

    return float3(
        d.x * a * cos(f),
        a * sin(f),
        d.y * a*cos(f)
    );
}

#endif //WAVE_LIB_HLSL