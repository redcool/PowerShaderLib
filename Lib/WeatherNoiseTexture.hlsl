/***
    get noise from texture
    like : noise4Layer texture
*/
#if !defined(WEATHER_NOISE_TEX_HLSL)
#define WEATHER_NOISE_TEX_HLSL

#define DEFAULT_RATE half4(0.1,0.2,0.3,0.4)

TEXTURE2D(_WeatherNoiseTexture);SAMPLER(sampler_WeatherNoiseTexture);

/**
    get noise,return [-,1]
*/
float SampleWeatherNoise(TEXTURE2D_PARAM(tex,tex_Sampler),float2 uv,half4 ratio = DEFAULT_RATE ){
    float4 n4 = SAMPLE_TEXTURE2D(tex,tex_Sampler,uv*0.1);
    // simple version
    #if defined(SIMPLE_NOISE_TEX)
    return n4.w;
    #endif
    // full version
    float n = dot(n4,ratio);
    return n.x;
}

float SampleWeatherNoise(float2 uv,half4 ratio = DEFAULT_RATE ){
    float n = SampleWeatherNoise(TEXTURE2D_ARGS(_WeatherNoiseTexture,sampler_WeatherNoiseTexture),uv,ratio);
    return n*2-1;
}

float SampleWeatherNoiseLOD(float2 uv,half lod,half4 ratio = DEFAULT_RATE ){
    float4 n = SAMPLE_TEXTURE2D_LOD(_WeatherNoiseTexture,sampler_WeatherNoiseTexture,uv*0.1,lod);
    return dot(n,ratio);
}

#endif //WEATHER_NOISE_TEX_HLSL