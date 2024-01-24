#if !defined(NATURE_LIB_HLSL)
#define NATURE_LIB_HLSL
#include "NodeLib.hlsl"
#include "MathLib.hlsl"
#include "WeatherNoiseTexture.hlsl"
/**
    override this vars
*/
#define IsRainOn() (_IsGlobalRainOn)
#define IsSnowOn() (_IsGlobalSnowOn)
#define IsWindOn() (_IsGlobalWindOn)

/**
    controlled by WeahterControl.cs
*/
float4 _GlobalWindDir; /*global (xyz)wind direction,w : wind intensity*/
float _GlobalSnowIntensity; 
float _GlobalRainIntensity;

half _IsGlobalRainOn;
half _IsGlobalSnowOn;
half _IsGlobalWindOn;



float4 SmoothCurve( float4 x ) {
    return x * x *( 3.0 - 2.0 * x );
}
float4 TriangleWave( float4 x ) {
    return abs( frac( x + 0.5 ) * 2.0 - 1.0 );
}
float4 SmoothTriangleWave( float4 x ) {
    return SmoothCurve( TriangleWave( x ) );
}

float CalcWorldNoise(float3 worldPos,float4 tilingOffset,float3 windDir){
    // cross noise
    float2 noiseUV = worldPos.xz * tilingOffset.xy+ windDir.xz * tilingOffset.zw* _Time.y;

    float noise =0;
    // noise version
    // noise += unity_gradientNoise(noiseUV) + 0.5;
    // noise += unity_gradientNoise(noiseUV2) + 0.5;

    // texture version
    noise += SampleWeatherNoise(noiseUV,half4(0.05,0.15,0.3,0.5));
    return noise;

    // full version
    // float2 noiseUV2 = worldPos.xz * tilingOffset.xy + float2(windDir.x * -_Time.x,0);
    // noise += SampleWeatherNoise(noiseUV2,half4(0.05,0.15,0.3,0.5));
    // noise = noise * 0.5+0.5;
    // return noise;  
}

// Detail bending
inline float4 AnimateVertex(float4 pos, float3 normal, float4 animParams,float4 windDir)
{
    // animParams stored in color
    // animParams.x = branch phase
    // animParams.y = edge flutter factor
    // animParams.z = primary factor
    // animParams.w = secondary factor

    float fDetailAmp = 0.1f;
    float fBranchAmp = 0.3f;

    // Phases (object, vertex, branch)
    float fObjPhase = dot(unity_ObjectToWorld._14_24_34, 1);
    float fBranchPhase = fObjPhase + animParams.x;

    float fVtxPhase = dot(pos.xyz, animParams.y + fBranchPhase);

    // x is used for edges; y is used for branches
    float2 vWavesIn = _Time.yy + float2(fVtxPhase, fBranchPhase );

    // 1.975, 0.793, 0.375, 0.193 are good frequencies
    float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);

    vWaves = SmoothTriangleWave( vWaves );
    float2 vWavesSum = vWaves.xz + vWaves.yw;

    // Edge (xz) and branch bending (y)
    float3 bend = animParams.y * fDetailAmp * normal.xyz;
    bend.y = animParams.w * fBranchAmp;
    pos.xyz += ((vWavesSum.xyx * bend) + (windDir.xyz * vWavesSum.y * animParams.w)) * windDir.w;

    // Primary bending
    // Displace position
    pos.xyz += animParams.z * windDir.xyz;

    return pos;
}
/**
    demo:
    shader : 
        [Header(Wind)]
        [GroupToggle(_,_WIND_ON)]_WindOn("_WindOn (need vertex color.r)",float) = 0
        [GroupVectorSlider(branch edge globalOffset flutterOffset,0_0.4 0_0.5 0_0.6 0_0.06)]_WindAnimParam("_WindAnimParam(x:branch,edge,z : global offset,w:flutter offset)",vector) = (1,1,0.1,0.3)
        [GroupVectorSlider(WindVector Intensity,0_1)]_WindDir("_WindDir,dir:(xyz),Intensity:(w)",vector) = (1,0.1,0,0.5)
        _WindSpeed("_WindSpeed",range(0,1)) = 0.3

    vertex code:

    float4 attenParam = v.color.x;
    worldPos = WindAnimationVertex(worldPos,v.vertex.xyz,o.normal,attenParam * _WindAnimParam, _WindDir,_WindSpeed).xyz;
*/
float4 WindAnimationVertex( float3 worldPos,float3 vertex,float3 normal,float4 atten_AnimParam,float4 windDir,float windSpeed){
    float localWindIntensity = windDir.w;
    //Apply Global wind,  (xyz : dir, w : intensity)
    windDir.xyz += _GlobalWindDir.xyz;
    windDir.w *= _GlobalWindDir.w;

    // apply perlin noise
    float gradientNoise = unity_gradientNoise(worldPos.xz*0.1 + windDir.xz * _Time.y * windSpeed);
    // float gradientNoise = InterleavedGradientNoise(worldPos.xz*0.1 + windDir.xz * _Time.y * windSpeed);
    atten_AnimParam.w += localWindIntensity * gradientNoise*0.3;

    // apply y atten
    float yAtten = saturate(vertex.y/10); // local position'y atten
    atten_AnimParam *= yAtten;

    windDir.xyz = clamp(windDir.xyz,-1,1);
    float4 animPos = AnimateVertex(float4(worldPos,1),normal,atten_AnimParam,windDir);
    return animPos;
}

/**
    worldPos : 世界坐标
    vertex : 局部坐标
    bend : 弯曲强度
    dir : 风力方向
    noiseUV : 用于计算连续噪波的输入
    noiseSpeed  : 噪波的运动速度
    noiseScale : 噪波的缩放
    noiseStrength : 噪波的强度
*/
void SimpleWave(inout float3 worldPos,float3 vertex,float3 vertexColor,float bend,float3 dir,float2 noiseUV,float noiseSpeed,float noiseScale,float noiseStrength){
    float y = vertex.y * bend * _CosTime.w * 0.01+ 1;
    float y2 = y*y;
    float y4 = y2*y2;
    dir *= (y4-y2);

    noiseUV += _Time.xx * noiseSpeed;
    float noise = 0;
    Unity_GradientNoise_half(noiseUV,noiseScale,noise/**/);
    dir.xz += noise * noiseStrength;
    
    float2 offsetPos = lerp(0,dir.xz,vertexColor.xy);
    worldPos.xz += offsetPos;
}

/**
    Simple Snow from albedo
*/
float3 MixSnow(float3 albedo,float3 snowColor,float intensity,float3 worldNormal,bool applyEdgeOn){
    float dirAtten = saturate(dot(worldNormal,_GlobalWindDir.xyz)); // filter by dir

    float rate = 0;
    half upAtten = dot(worldNormal,half3(0,1,0));
    rate = saturate(upAtten + dirAtten);

    UNITY_BRANCH if(applyEdgeOn){
        float g = dot(float3(0.2,0.7,0.02),albedo) ;
        rate = smoothstep(.1,.2,rate*g);
    }
    return lerp(albedo,snowColor,rate * intensity * _GlobalSnowIntensity);
}

float3 ComputeRipple(TEXTURE2D_PARAM(rippleTex,sampler_RippleTex),float2 uv, float t)
{
	float4 ripple = SAMPLE_TEXTURE2D(rippleTex,sampler_RippleTex, uv);
	ripple.yz = ripple.yz * 2.0 - 1.0;

	float drop = frac(ripple.a + t);
	float move = ripple.x + drop -1;
	float dropFactor = 1 - saturate(drop);

	float final = dropFactor * sin(clamp(move*9,0,4)*PI);
	return float3(ripple.yz * final,1);
}

float3 CalcRipple(TEXTURE2D_PARAM(rippleTex,sampler_RippleTex),float2 rippleUV,float speed,float intensity){
    half3 rippleCol = ComputeRipple(rippleTex,sampler_RippleTex,frac(rippleUV),_Time.x * speed);
    return rippleCol * intensity;
}

float2 CalcRippleUV(float3 worldPos,float4 rippleTex_ST,float rippleOffsetAutoStop){
    float2 uvOffset = UVOffset(rippleTex_ST.zw,rippleOffsetAutoStop);
    float2 rippleUV = worldPos.xz * rippleTex_ST.xy + uvOffset;
    return rippleUV;
}


/** 
    rain flow atten
*/
float GetRainFlowAtten(float3 worldPos,float3 vertexNormal,float rainIntensity,float rainSlopeAtten,float rainHeight){
    float atten = saturate(dot(vertexNormal,float3(0,1,0))  - rainSlopeAtten);
    atten *= saturate(rainHeight - worldPos.y);
    atten *= rainIntensity;
    return atten;
}

/**
    rain pixel atten mode
    
    #define RAIN_MASK_PBR_SMOOTHNESS 1
    #define RAIN_MASK_MAIN_TEX_ALPHA 2
*/
float GetRainRippleAtten(float smoothness,float mainTexAlpha,float rainMaskFrom){
    float attenMaskMode[3] = {1,smoothness,mainTexAlpha};
    return attenMaskMode[rainMaskFrom];
}

float2 GetRainFlowUVOffset(out float rainNoise,float rainAtten,float3 worldPos,float4 rainFlowTilingOffset,float rainFlowIntensity){
    rainNoise = 0;
    branch_if(!rainFlowIntensity)
        return 0;
    // flow
    rainNoise = CalcWorldNoise(worldPos,rainFlowTilingOffset,_GlobalWindDir.xyz/*NatureLib.hlsl*/);
    return rainNoise*0.02 * rainAtten * rainFlowIntensity;
}

void ApplyRainPbr(inout float3 albedo,inout float metallic,inout float smoothness,float3 rainColor,float rainMetallic,float rainSmoothness,float rainIntensity){
    // float3 worldPos = ScreenToWorldPos(screenUV);
    albedo *= lerp(1,rainColor.xyz,rainIntensity);
    metallic = lerp(metallic , rainMetallic, rainIntensity);
    smoothness = lerp(smoothness , rainSmoothness , rainIntensity);
}

half3 CalcCloudShadow(TEXTURE2D_PARAM(tex,samplerTex),float3 worldPos,float4 noiseTilingOffset,bool isAutoOffsetStop,float noiseRangeMin,float noiseRangeMax,
float4 shadowColor,float shadowIntensity,float baseShadowIntensity){
    float2 uv = worldPos.xz * noiseTilingOffset.xy + UVOffset(noiseTilingOffset.zw,isAutoOffsetStop);
    float noise = SampleWeatherNoise(TEXTURE2D_ARGS(tex,samplerTex),uv,half4(0.1,0.2,0.3,0.4));
    noise = smoothstep(noiseRangeMin,noiseRangeMax,noise);

    float rate = saturate(noise * shadowIntensity + baseShadowIntensity);
    
    return lerp(shadowColor.xyz,1,rate );
}


#endif //NATURE_LIB_HLSL