#if !defined(SAMPLE_STATES_HLSL)
#define SAMPLE_STATES_HLSL
    // all states
    SamplerState sampler_PointClamp;
    SamplerState sampler_LinearClamp;
    SamplerState sampler_PointRepeat;
    SamplerState sampler_LinearRepeat;

    // use this for default
    #define SAMPLE_STATE sampler_PointClamp
#endif //SAMPLE_STATES_HLSL