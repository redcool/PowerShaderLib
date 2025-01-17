/**
    used for SFC
*/
Shader "Unlit/Hidden/CommonBlur"
{
    Properties
    {
        [GroupHeader(Blur For transform object)]
        // _SourceTex ("Texture", 2D) = "white" {}
        _Fade("_Fade",range(0,1)) = 0.5

        [Header(Blur Mode)]
        // [KeywordEnum(None,X3,X7)]
        [GroupEnum(,None _BOX_BLUR_X3 _GAUSS_X7,true)]
        _BlurMode("_BlurMode",int) = 0

        [GroupToggle]_IsBlitTriangle("_IsBlitTriangle",float) = 1

        [Header(Blur Options)]
        _BlurScale("_BlurScale",range(0.5,5)) = 1

        _NoiseTex("_NoiseTex",2d) = "bump"{}
        _NormalScale("_NormalScale",float) = 1
    }

HLSLINCLUDE
    #include "../../Lib/UnityLib.hlsl"
    #include "../../Lib/BlurLib.hlsl"
    #include "../../Lib/BlitLib.hlsl"
    #include "../../Lib/Colors.hlsl"    
    #include "../../Lib/ColorSpace.hlsl"


    struct appdata
    {
        float4 vertex : POSITION;
        float4 uv : TEXCOORD0;
        uint vid:SV_VERTEXID;
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float4 uv : TEXCOORD0;
    };
    sampler2D _SourceTex;
    // float4 _SourceTex_ST;
    float4 _SourceTex_TexelSize;
    
    sampler2D _NoiseTex;
CBUFFER_START(UnityPerMaterial)
    float _Fade;
    float _BlurScale;
    float4 _NoiseTex_ST;
    float _NormalScale;
    float _IsBlitTriangle;
CBUFFER_END
    v2f vert (appdata v)
    {
        v2f o;

        if(_IsBlitTriangle){
            FullScreenTriangleVert(v.vid,o.vertex/**/,o.uv.xy/**/);
            o.uv.zw = o.uv.xy;
        }else{
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.uv.xy;
            o.uv.zw = TRANSFORM_TEX(v.uv,_NoiseTex);
        }
        
        return o;
    }
ENDHLSL

    SubShader
    {
        LOD 100
        Cull off
        zwrite off
        ztest always

        Pass
        {
            name "blurHV"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _BOX_BLUR_X3 _GAUSS_X7
            #pragma multi_compile_fragment _ _SRGB_TO_LINEAR_CONVERSION _LINEAR_TO_SRGB_CONVERSION

            #if defined(_GAUSS_X7) || defined(_BOX_BLUR_X3)
                #define CALC_BLUR
            #endif

            float4 frag (v2f i) : SV_Target
            {
                float2 noiseTex = 0;
                #if defined(_GAUSS_X7) || defined(_BOX_BLUR_X3)
                    noiseTex = tex2D(_NoiseTex,i.uv.zw).xy * _NormalScale;
                #endif

                float2 screenUV = i.uv;

                float4 col = 0;
                #if defined(_GAUSS_X7)
                    col.xyz += Gaussian7(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(0,1) + noiseTex));
                    col.xyz += Gaussian7(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(1,0) + noiseTex));
                    col *= 0.5;
                #elif defined(_BOX_BLUR_X3)
                    col.xyz += BoxBlur3(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(0,1) + noiseTex));
                    col.xyz += BoxBlur3(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(1,0) + noiseTex));
                    col *= 0.5;
                #else
                    col = tex2D(_SourceTex,screenUV);
                #endif

                // sample the texture, for blend
                #if defined(CALC_BLUR)
                    float4 mainTex = tex2D(_SourceTex,i.uv.xy);
                    col = lerp(col,mainTex,_Fade);
                    col.a = mainTex.a;
                #endif

                // change color space
                LinearGammaAutoChange(col,false);

                return col;
            }
            ENDHLSL
        }
        // 1
        Pass
        {
            name "blurH"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _BOX_BLUR_X3 _GAUSS_X7
            #pragma multi_compile_fragment _ _SRGB_TO_LINEAR_CONVERSION _LINEAR_TO_SRGB_CONVERSION

            #if defined(_GAUSS_X7) || defined(_BOX_BLUR_X3)
                #define CALC_BLUR
            #endif

            float4 frag (v2f i) : SV_Target
            {
                float2 noiseTex = 0;
                #if defined(_GAUSS_X7) || defined(_BOX_BLUR_X3)
                    noiseTex = tex2D(_NoiseTex,i.uv.zw).xy * _NormalScale;
                #endif

                float2 screenUV = i.uv;

                float4 col = 0;
                #if defined(_GAUSS_X7)
                    col.xyz += Gaussian7(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(0,1) + noiseTex));

                #elif defined(_BOX_BLUR_X3)
                    col.xyz += BoxBlur3(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(0,1) + noiseTex));

                #else
                    col = tex2D(_SourceTex,screenUV);
                #endif

                // sample the texture, for blend
                #if defined(CALC_BLUR)
                    float4 mainTex = tex2D(_SourceTex,i.uv.xy);
                    col = lerp(col,mainTex,_Fade);
                    col.a = mainTex.a;
                #endif

                // change color space
                LinearGammaAutoChange(col,false);

                return col;
            }
            ENDHLSL
        }
        // 2
        Pass
        {
            name "blurV"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _BOX_BLUR_X3 _GAUSS_X7
            #pragma multi_compile_fragment _ _SRGB_TO_LINEAR_CONVERSION _LINEAR_TO_SRGB_CONVERSION

            #if defined(_GAUSS_X7) || defined(_BOX_BLUR_X3)
                #define CALC_BLUR
            #endif

            float4 frag (v2f i) : SV_Target
            {
                float2 noiseTex = 0;
                #if defined(_GAUSS_X7) || defined(_BOX_BLUR_X3)
                    noiseTex = tex2D(_NoiseTex,i.uv.zw).xy * _NormalScale;
                #endif

                float2 screenUV = i.uv;

                float4 col = 0;
                #if defined(_GAUSS_X7)
                    col.xyz += Gaussian7(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(1,0) + noiseTex));
                #elif defined(_BOX_BLUR_X3)
                    col.xyz += BoxBlur3(_SourceTex,screenUV, _SourceTex_TexelSize.xy * (_BlurScale * float2(1,0) + noiseTex));
                #else
                    col = tex2D(_SourceTex,screenUV);
                #endif

                // sample the texture, for blend
                #if defined(CALC_BLUR)
                    float4 mainTex = tex2D(_SourceTex,i.uv.xy);
                    col = lerp(col,mainTex,_Fade);
                    col.a = mainTex.a;
                #endif

                // change color space
                LinearGammaAutoChange(col,false);

                return col;
            }
            ENDHLSL
        }        
    }
}
