#if !defined(WEATHER_NOISE_TEX_HLSL)
// noise4Layer texture
TEXTURE2D(_WeatherNoiseTexture);SAMPLER(sampler_WeatherNoiseTexture);

float SampleWeatherNoise(float2 uv,half4 ratio=half4(.5,.25,.0125,.063)){
    float4 n4 = SAMPLE_TEXTURE2D(_WeatherNoiseTexture,sampler_WeatherNoiseTexture,uv*0.1);
    // simple version
    // return n4.w*2-1;
    // full version
    float n = dot(n4,ratio);
    n = n*2-1;
    return n.x;
}

float SampleWeatherNoiseLOD(float2 uv,half lod){
    float4 n = SAMPLE_TEXTURE2D_LOD(_WeatherNoiseTexture,sampler_WeatherNoiseTexture,uv*0.1,lod);
    return dot(n,half4(0.5,0.25,0.125,0.06).wzyx);
}

#endif //WEATHER_NOISE_TEX_HLSL