Shader "Unlit/TestNoiseLib"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Progress("_Progress",range(0,1))=0
    }

CGINCLUDE

ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "../Lib/NoiseLib.hlsl"

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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Progress;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = (i.worldPos * 5);

                // float3 n3 = ValueNoise33(worldPos);
                // return n3.xyzx;
    float p = GradientNoise(worldPos.x);
   
    // float f = frac(worldPos.x);
    // p = (N11(floor(worldPos.x))*2-1)*f;

    // float dist = abs(p - i.worldPos.y);
    // return smoothstep(0.001,0.005,dist);

                // float pn = GradientNoise(worldPos.xyz);
                float3 pn = VoronoiNoise33(worldPos.xyz);
                // pn =lerp(pn, VoronoiNoise1(worldPos.xy),_Progress);
                // return pn.z;
                return smoothstep(0.05,0.051,pn.z);
            }
            ENDCG
        }
    }
}
