Shader "Unlit/TestCoordinate"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Angle("_Angle",range(0,1)) = 0
    }

    CGINCLUDE
#include "../Lib/CoordinateSystem.hlsl"
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Angle;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 polar = ToPolar(i.uv);
                polar.x += _Angle;//[0,1]
                float2 coord = ToCartesian(polar);
                // sample the texture
                fixed4 col = tex2D(_MainTex, coord);

                return col;
            }
            ENDCG
        }
    }
}
