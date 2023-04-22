Shader "Hidden/Utils/DeferredShading"
{
    Properties
    {
        // _SourceTex ("Texture", 2D) = "white" {}
    }

    HLSLINCLUDE
    // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../Lib/UnityLib.hlsl"
    #include "../URPLib/Lighting.hlsl"
    #include "../Lib/ScreenTextures.hlsl"
    #include "../Lib/BlitLib.hlsl"
    #include "../Lib/Colors.hlsl"

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };
    struct appdata{
        float3 vertex:POSITION;
        float2 uv : TEXCOORD;
    };

    sampler2D _GBuffer0;
    sampler2D _GBuffer1;
    

    v2f vert (appdata i)
    {
        v2f o;
        // FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);
        o.vertex = (i.vertex.xy*2,0);
        o.uv = i.uv;
        return o;
    }

    float4 frag (v2f i) : SV_Target
    {
        float4 gbuffer0 = tex2D(_GBuffer0,i.uv);// color
        float4 gbuffer1 = tex2D(_GBuffer1,i.uv); // normal

        float3 albedo = gbuffer0.xyz;

        float3 normal = gbuffer1.xyz;
        normal.z = sqrt(1-gbuffer1.x*gbuffer1.x-gbuffer1.y*gbuffer1.y);

        float depth = GetScreenDepth(i.uv);
        float3 worldPos = ComputeWorldSpacePosition(i.uv,depth,UNITY_MATRIX_I_VP);
        Light mainLight = GetMainLight();

        float3 v = _WorldSpaceCameraPos.xyz;
        float3 l = mainLight.direction;
        float3 h = normalize(l+v);

        float nv = saturate(dot(normal,v));
        float nl = saturate(dot(normal,l));
        float nh = saturate(dot(normal,h));

        float4 col = 0;
        col.xyz = nh;

        return col;
    }
    ENDHLSL

    SubShader
    {
        Cull off
        zwrite off
        ztest always

        Pass
        {
            Tags{"LightMode"="DeferredShading"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
