#if !defined(BLUR_LIB_HLSL)
#define BLUR_LIB_HLSL


//----------------
// Gaussain + Box blur, use Sampler2D
//----------------
const static half WEIGHTS_3[3] = {0.147761,0.118318,0.0947416};
const static half WEIGHTS_7[4] = {0.3,0.2,0.1,0.05};

half3 Gaussian7(sampler2D tex,half2 uv,half2 uvOffset){
    half4 c = tex2D(tex,uv+0) * WEIGHTS_7[0];
    for(int i=1;i<4;i++){
        c += tex2D(tex,uv + uvOffset * i) * WEIGHTS_7[i];
        c += tex2D(tex,uv - uvOffset * i) * WEIGHTS_7[i];
    }
    return c.xyz;
}

half3 BoxBlur3(sampler2D tex,half2 uv,half2 uvOffset){
    half4 c = tex2D(tex,uv);
    c += tex2D(tex,uv + uvOffset);
    c += tex2D(tex,uv - uvOffset);
    return c.xyz*0.33;
}

#if !defined(USE_SAMPLER2D)
//----------------
// Box blur
// demo : BoxBlur(_MainTex,sampler_MainTex,i.texcoord,_MainTex_TexelSize.xy * _BlurSize* float2(1,0),_StepCount);
//----------------
half4 BoxBlur(TEXTURE2D_PARAM(tex,state),float2 uv,float2 uvOffset,int stepCount=10){
    half4 c = 0;
    half halfStepCount = stepCount*0.5;
    for(int i=0;i<stepCount;i++){
        c += SAMPLE_TEXTURE2D(tex,state,uv + uvOffset * (i-halfStepCount));
    }
    return c * rcp(stepCount);
}

//BoxBlur: 4 sides average 
float4 SampleBox(TEXTURE2D_PARAM(tex,state), float4 texel, float2 uv, float delta) {
	float2 p = texel.xy * delta;
	float4 c = SAMPLE_TEXTURE2D(tex, state, uv + float2(-1, -1) * p);
	c += SAMPLE_TEXTURE2D(tex, state, uv + float2(1, -1) * p);
	c += SAMPLE_TEXTURE2D(tex, state, uv + float2(-1, 1) * p);
	c += SAMPLE_TEXTURE2D(tex, state, uv + float2(1, 1) * p);

	return c * 0.25;
    // return BoxBlur(tex,state,uv,texel.xy * delta);
}

//BoxBlur: 4 sides weights
float4 SampleBox(TEXTURE2D_PARAM(tex,state),float4 texel,float2 uv, float delta,float sideWeight,float centerWeight=0) {
    float2 p = texel.xy * delta;
    float4 c = SAMPLE_TEXTURE2D(tex,state,uv + float2(-1,-1) * p) * sideWeight;
    c += SAMPLE_TEXTURE2D(tex,state,uv + float2(1,-1) * p) * sideWeight;
    c += SAMPLE_TEXTURE2D(tex,state,uv + float2(-1,1) * p) * sideWeight;
    c += SAMPLE_TEXTURE2D(tex,state,uv + float2(1,1) * p) * sideWeight;
    //c += SAMPLE_TEXTURE2D(tex,state,uv) * centerWeight;
    return c;
}

//----------------
// Gaussian blur
//----------------
const static float gaussWeights[4]={0.00038771,0.01330373,0.11098164,0.22508352};

float4 GaussBlur(TEXTURE2D_PARAM(tex,sampler_tex),float2 uv,float2 offset,bool samplerCenter){
    float4 c = 0;
    if(samplerCenter){
        c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv) * gaussWeights[3];
    }
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv + offset) * gaussWeights[2];
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv - offset) * gaussWeights[2];

    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv + offset * 2) * gaussWeights[1];
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv - offset * 2) * gaussWeights[1];

    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv + offset * 3) * gaussWeights[0];
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv - offset * 3) * gaussWeights[0];
    return c;
}

float4 SampleGaussian(TEXTURE2D_PARAM(tex,state), float2 texel, float2 uv) {
	float4 c = GaussBlur(tex,state,uv,float2(texel.x,0),true);
	c += GaussBlur(tex,state,uv,float2(0,texel.y),true);
	return c;
}


//----------------
// Dir blur
//----------------
#define DIR_BLUR_SAMPLES 6
const static float dirBlurWeights[DIR_BLUR_SAMPLES] = {-0.03,-0.02,-0.01,0.01,0.02,0.03};
float4 SampleDirBlur(TEXTURE2D_PARAM(tex,state),float2 uv,float2 dir){
    float4 c = 0;
    for(int i=0;i<DIR_BLUR_SAMPLES;i++){
        c += SAMPLE_TEXTURE2D(tex,state,(uv + dir * dirBlurWeights[i]));
    }
    return c / (DIR_BLUR_SAMPLES);
}


//----------------
// Kawase blur
//----------------
float4 KawaseBlur(TEXTURE2D_PARAM(tex,state),float2 uv,float2 texelSize,float blurSize){
    const half2 offsets[4] = {-1,-1, 1,1, -1,1, 1,-1};
    float4 c = 0;
    for(int x=0;x<4;x++){
        c += SAMPLE_TEXTURE2D(tex,state,uv + offsets[x] * texelSize * blurSize);
    }
    c *= 0.25;
    return c;
}
#endif //USE_SAMPLER2D

#endif