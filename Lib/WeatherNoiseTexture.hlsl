/***
    get noise from _WeatherNoiseTexture
*/
#if !defined(WEATHER_NOISE_TEX_HLSL)
#define WEATHER_NOISE_TEX_HLSL
// noise4Layer texture
TEXTURE2D(_WeatherNoiseTexture);SAMPLER(sampler_WeatherNoiseTexture);
/**
    get noise,return [-,1]
*/
float SampleWeatherNoise(float2 uv,half4 ratio=half4(.5,.25,.0125,.063)){
    float4 n4 = SAMPLE_TEXTURE2D(_WeatherNoiseTexture,sampler_WeatherNoiseTexture,uv*0.1);
    // simple version
    #if defined(SIMPLE_NOISE_TEX)
    return n4.w*2-1;
    #endif
    // full version
    float n = dot(n4,ratio);
    n = n*2-1;
    return n.x;
}

float SampleWeatherNoiseLOD(float2 uv,half lod,half4 ratio=half4(.5,.25,.0125,.063)){
    float4 n = SAMPLE_TEXTURE2D_LOD(_WeatherNoiseTexture,sampler_WeatherNoiseTexture,uv*0.1,lod);
    return dot(n,ratio);
}

#endif //WEATHER_NOISE_TEX_HLSL