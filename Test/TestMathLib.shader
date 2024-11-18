Shader "Hidden/Unlit/TestMathLib"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Axis("Axis",vector)=(1,0,0,0)
        _Angle("_Angle",range(0,6.28))=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "../Lib/MathLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 n:NORMAL;
                float4 t:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Axis;
            float _Angle;

            v2f vert (appdata v)
            {
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                float3 n = mul(v.n,unity_WorldToObject);
                float3 t = normalize(mul(unity_ObjectToWorld,v.t));
                float3 b = normalize(cross(n,t)) * v.t.w;

// float3 forward = normalize(worldPos);
// float3 axis = (cross(n,forward));
float3x3 rotMat = AngleAxis3x3(_Angle,_Axis);
worldPos = mul(rotMat,worldPos);

                v2f o;
                o.vertex = mul(unity_MatrixVP,float4(worldPos,1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
