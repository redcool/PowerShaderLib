/**
    MainLight Shadow
*/
#if !defined(MAIN_LIGHT_SHADOW_HLSL)
#define MAIN_LIGHT_SHADOW_HLSL

#if defined(_RECEIVE_SHADOWS_ON)
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)
        #define MAIN_LIGHT_CALCULATE_SHADOWS

        #if defined(_MAIN_LIGHT_SHADOWS) || (defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT))
            #define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
    #endif

    #if defined(_ADDITIONAL_LIGHT_SHADOWS)
        #define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
    #endif
#endif

#if defined(LIGHTMAP_ON) || defined(LIGHTMAP_SHADOW_MIXING) || defined(SHADOWS_SHADOWMASK)
    #define CALCULATE_BAKED_SHADOWS
#endif


TEXTURE2D_SHADOW(_MainLightShadowmapTexture);SAMPLER_CMP(sampler_MainLightShadowmapTexture);

#if defined(SHADER_API_MOBILE)
    static const int SOFT_SHADOW_COUNT = 2;
    static const float SOFT_SHADOW_WEIGHTS[] = {0.2,0.4,0.4};
#else
    static const int SOFT_SHADOW_COUNT = 4;
    static const float SOFT_SHADOW_WEIGHTS[] = {0.2,0.25,0.25,0.15,0.15};
#endif 

#ifndef SHADER_API_GLES3
CBUFFER_START(MainLightShadows)
#endif
    #define MAX_SHADOW_CASCADES 4
    half4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
    float4      _CascadeShadowSplitSpheres0;
    float4      _CascadeShadowSplitSpheres1;
    float4      _CascadeShadowSplitSpheres2;
    float4      _CascadeShadowSplitSpheres3;
    float4      _CascadeShadowSplitSphereRadii;
    float4       _MainLightShadowOffset0;
    float4       _MainLightShadowOffset1;
    float4       _MainLightShadowOffset2;
    float4       _MainLightShadowOffset3;
    float4       _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise, z: oneOverFadeDist, w: minusStartFade)
    float4      _MainLightShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
// CBUFFER_END
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif

#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0

float ComputeCascadeIndex(float3 positionWS)
{
    float3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
    float3 fromCenter1 = positionWS - _CascadeShadowSplitSpheres1.xyz;
    float3 fromCenter2 = positionWS - _CascadeShadowSplitSpheres2.xyz;
    float3 fromCenter3 = positionWS - _CascadeShadowSplitSpheres3.xyz;
    float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

    float4 weights = float4(distances2 < _CascadeShadowSplitSphereRadii);
    weights.yzw = saturate(weights.yzw - weights.xyz);

    return 4 - dot(weights, float4(4, 3, 2, 1));
}

/*
    call TransformWorldToShadowCoord in vs will be see artifact
    can call in ps
*/
float4 TransformWorldToShadowCoord(float3 positionWS)
{
#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
    float cascadeIndex = ComputeCascadeIndex(positionWS);
#else
    float cascadeIndex = 0;
#endif

    float4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));

    return float4(shadowCoord.xyz, cascadeIndex);
}

    float4 _ShadowBias; // x: depth bias, y: normal bias
    float _MainLightShadowOn; //send  from PowerUrpLitFeature

    float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection,float matShadowNormalBias=0,float matShadowDepthBias=0)
    {
        float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
        float scale = invNdotL * (_ShadowBias.y + matShadowNormalBias);

        // normal bias is negative since we want to apply an inset normal offset
        positionWS = lightDirection * (_ShadowBias.xxx + matShadowDepthBias) + positionWS;
        positionWS = normalWS * scale.xxx + positionWS;
        return positionWS;
    }
    
    float GetShadowFade(float3 positionWS)
    {
        float3 camToPixel = positionWS - _WorldSpaceCameraPos;
        float distanceCamToPixel2 = dot(camToPixel, camToPixel);

        float fade = saturate(distanceCamToPixel2 * _MainLightShadowParams.z + _MainLightShadowParams.w);
        return fade;
    }

    float SampleShadowmap(TEXTURE2D_SHADOW_PARAM(shadowMap,sampler_ShadowMap),float4 shadowCoord,float shadowSoftScale){
        float shadow = SAMPLE_TEXTURE2D_SHADOW(shadowMap,sampler_ShadowMap, shadowCoord.xyz);

        // return shadow;
        #if defined(_SHADOWS_SOFT)
            shadow *= SOFT_SHADOW_WEIGHTS[0];

            float2 psize = _MainLightShadowmapSize.xy * shadowSoftScale;
            const float2 uvs[] = { float2(-psize.x,0),float2(0,psize.y),float2(psize.x,0),float2(0,-psize.y) };

            float2 offset = 0;
            for(int x=0;x< SOFT_SHADOW_COUNT;x++){
                offset = uvs[x] ;
                shadow +=SAMPLE_TEXTURE2D_SHADOW(shadowMap,sampler_ShadowMap, float3(shadowCoord.xy + offset,shadowCoord.z)) * SOFT_SHADOW_WEIGHTS[x+1];
            }
        #endif 
        
        return shadow;
    }

    float MixRealtimeAndBakedShadows(float realtimeShadow, float bakedShadow, float shadowFade)
    {
    #if defined(LIGHTMAP_SHADOW_MIXING)
        return min(lerp(realtimeShadow, 1, shadowFade), bakedShadow);
    #else
        return lerp(realtimeShadow, bakedShadow, shadowFade);
    #endif
    }

    float BakedShadow(float4 shadowMask, float4 occlusionProbeChannels)
    {
        // Here occlusionProbeChannels used as mask selector to select shadows in shadowMask
        // If occlusionProbeChannels all components are zero we use default baked shadow value 1.0
        // This code is optimized for mobile platforms:
        // float bakedShadow = any(occlusionProbeChannels) ? dot(shadowMask, occlusionProbeChannels) : 1.0h;
        float bakedShadow = float(1.0) + dot(shadowMask - float(1.0), occlusionProbeChannels);
        return bakedShadow;
    }

    float CalcShadow (float4 shadowCoord,float3 worldPos)
    {
        float shadow = 1;
        #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE)
        {
            //shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture, shadowCoord.xyz);
            shadow = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture),shadowCoord,_MainLightShadowSoftScale);
            shadow = lerp(1,shadow,_MainLightShadowParams.x); // shadow intensity
            shadow = BEYOND_SHADOW_FAR(shadowCoord) ? 1 : shadow; // shadow range

            float shadowFade = GetShadowFade(worldPos); 
            shadowFade = shadowCoord.w == 4 ? 1.0 : shadowFade;
            
            shadow = lerp(shadow,1,shadowFade);
        }
        #endif
        return shadow;
    }

    float CalcShadow (float4 shadowCoord,float3 worldPos,float4 shadowMask,bool receiveShadow,float softScale)
    {
        float shadow = 1;
        
        #if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
            // if(receiveShadow){
                //shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture, shadowCoord.xyz);
                shadow = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture),shadowCoord,softScale);
                shadow = lerp(1,shadow,_MainLightShadowParams.x); // shadow intensity
                shadow = BEYOND_SHADOW_FAR(shadowCoord) ? 1 : shadow; // shadow range

                // baked shadow
                #if defined(CALCULATE_BAKED_SHADOWS)
                    float bakedShadow = BakedShadow(shadowMask,_MainLightOcclusionProbes);
                #else
                    float bakedShadow = 1;
                #endif

                // shadow fade
                float shadowFade = GetShadowFade(worldPos); 
                // shadowFade = shadowCoord.w == 4 ? 1.0 : shadowFade;
                // mix 
                shadow = MixRealtimeAndBakedShadows(shadow,bakedShadow,shadowFade);
            // }
        #endif 
        return shadow;
    }

    #define MainLightShadow(shadowCoord,worldPos,shadowMask,receiveShadow,softScale) CalcShadow(shadowCoord,worldPos,shadowMask,receiveShadow,softScale) 

#endif //MAIN_LIGHT_SHADOW_HLSL