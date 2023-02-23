Shader "Character/Unlit/ShowOcclusion"
{
    Properties
    {
        _MainTex("_MainTex",2d)=""{}

        //
        _SnowFlakeIntensity("_SnowFlakeIntensity",float) = 1

        _JitterBlockSize("_JitterBlockSize",range(0,1)) = 0.1
        _JitterIntensity("_JitterIntensity",range(0,1)) = 1
        _VerticalJumpIntensity("_VerticalJumpIntensity",float) = 1
        _HorizontalShake("_HorizontalShake",float) = 1
        
        _ColorDriftSpeed("_ColorDriftSpeed",float) = 1
        _ColorDriftIntensity("_ColorDriftIntensity",float) = 1
        _HorizontalIntensity("_HorizontalIntensity",float) = 1
    }

HLSLINCLUDE
            #include "../Lib/UnityLib.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD1;
                float4 fogCoord:TEXCOORD2;
            };

            float _SnowFlakeIntensity,
            _JitterBlockSize,_JitterIntensity,
_VerticalJumpIntensity,_HorizontalShake,_ColorDriftSpeed,_ColorDriftIntensity,_HorizontalIntensity
            ;

            #include "../Lib/NoiseLib.hlsl"
            #include "../Lib/Colors.hlsl"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            half4 frag (v2f i) : SV_Target
            {
                float2 screenUV = (i.vertex.xy/_ScreenParams.xy * 2);

                // return ScreenDoor2(i.vertex,1);

                return Glitch(TEXTURE2D_ARGS(_MainTex,sampler_MainTex),screenUV,
                _SnowFlakeIntensity,
                _JitterBlockSize,_JitterIntensity,
                _VerticalJumpIntensity,_HorizontalShake,
                _ColorDriftSpeed,_ColorDriftIntensity,
                _HorizontalIntensity
                );

                
                float intensity = InterleavedGradientNoise(screenUV, 0);
// intensity *= InterleavedGradientNoise(screenUV*_NoiseScale.zw + _NoiseSpeed * _Time.y, 0);
                // float rAlpha = InterleavedGradientNoise(screenUV*10 * _NoiseScale.x +  _NoiseSpeed * _Time.y,0);
            }
ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
blend srcAlpha oneMinusSrcAlpha
        Pass
        {
            ztest greater

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _CLIP_ON


            ENDHLSL
        }
    }
}
