/**
    cmd.BlitTriangle
*/
Shader "Hidden/Utils/CopyColorScale"
{
    Properties
    {
        // _SourceTex ("Texture", 2D) = "white" {}
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../../Lib/BlitLib.hlsl"
    #include "../../Lib/Colors.hlsl"
    #include "../../Lib/ColorSpace.hlsl"    

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    TEXTURE2D(_SourceTex);
    float4 _SourceTex_TexelSize;

    bool _ApplyColorGrading;

SamplerState point_clamp_sampler;
SamplerState linear_clamp_sampler;

static const float threshold = 48.0 / 255.0;

float3 RGBtoYUV(float3 rgb) {
    return float3(
        dot(rgb, float3(0.299, 0.587, 0.114)),
        dot(rgb, float3(-0.169, -0.331, 0.5)),
        dot(rgb, float3(0.5, -0.419, -0.081))
    );
}

bool Diff(float3 c1, float3 c2) {
    float3 yuv1 = RGBtoYUV(c1);
    float3 yuv2 = RGBtoYUV(c2);
    return any(abs(yuv1 - yuv2) > float3(threshold, 0.008, 0.008));
}

#define texture(tex,uv) SAMPLE_TEXTURE2D(tex,point_clamp_sampler,uv)

float4 hq4x(float2 uv,float2 texelSize){
    float2 t1 = uv + texelSize;
    float2 t2 = uv + float2(texelSize.x,0);
    float2 t3 = uv + float2(0,texelSize.y);
    float2 t4 = uv - texelSize;

    float3 i1 = texture(_SourceTex, t1.xy).xyz;
    float3 i2 = texture(_SourceTex, t2.xy).xyz;
    float3 i3 = texture(_SourceTex, t3.xy).xyz;
    float3 i4 = texture(_SourceTex, t4.xy).xyz;

    float3 color = i1+i2+i3+i4;
    return half4(color.xyz,1)*0.25;
}


    v2f vert (uint vid:SV_VERTEXID)
    {
        v2f o;
        FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);

        return o;
    }

    float4 frag (v2f i) : SV_Target
    {
        float4 c = SAMPLE_TEXTURE2D(_SourceTex,point_clamp_sampler,i.uv);
        // return c;
        float4 col = hq4x(i.uv,_SourceTex_TexelSize.xy);

        if(_ApplyColorGrading)
            col.xyz = ApplyColorGradingLUT(col.xyz);

        // change color space
        LinearGammaAutoChange(col,false);

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
            blend[_FinalSrcMode][_FinalDstMode]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _SRGB_TO_LINEAR_CONVERSION _LINEAR_TO_SRGB_CONVERSION
            ENDHLSL
        }
    }
}
