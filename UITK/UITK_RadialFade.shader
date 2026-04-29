Shader "ShaderGraphs/UITK_RadialFade"
{
    Properties
    {
        // expose properties in the uitoolkit, so users can modify them in the material inspector or through code.
        _Progress ("Progress", Range(0, 1)) = 0.5

        [Header(Ramp)]
        [Toggle(_RAMP_MAP_ON)]_RampMapOn("_RampMapOn", int) = 0
        _RampMap("RampMap(r)", 2D) = "white" {}

        [Header(Mask)]
        _MaskMap("_MaskMap(r)", 2D) = "white" {}

        // below properties are hidden uitoolkit
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "isCustomUITKShader"="true"
            "Queue"="Transparent"
            // DisableBatching: <None>
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"=""
            "IgnoreProjector"="True"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }
        
        Pass
        {
            Name "Default"
        
            // Render State
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ZWrite Off
        
            HLSLPROGRAM
        
            // Pragmas
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag
                        
            #pragma shader_feature _RAMP_MAP_ON
            
            #include_with_pragmas "UITKDeclares.hlsl"
            

            CBUFFER_START(UnityPerMaterial)
                // UNITY_TEXTURE_STREAMING_DEBUG_VARS;
                float _Progress;
            CBUFFER_END

            TEXTURE2D(_MaskMap);SAMPLER(sampler_MaskMap);
            TEXTURE2D(_RampMap);SAMPLER(sampler_RampMap);
        
            float CalcRadialFading(float2 uv)
            {
                float2 center = uv * 2 - 1; // 将UV坐标转换为[-1, 1]范围
                float angle = atan2(center.x, center.y); // 计算角度,从下侧,顺时针为正,(交换xy,加负号,可以换方向)
                float normalizedAngle = (angle + 3.14159265) / (2 * 3.14159265); // 将角度归一化到[0, 1]范围
                return normalizedAngle;
            }

            void ApplyRadialFading(inout half4 color, float2 uv)
            {
                half mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv).r;
                color.a *= mask; // 将mask的alpha乘到颜色的alpha上

                #if defined(_RAMP_MAP_ON)
                    half rampValue = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, uv).r; // 从Ramp Map中采样
                    // alpha *= rampValue > _Progress; // 将Ramp Map的值乘到颜色的alpha上
                    clip(rampValue - _Progress); // 使用clip函数丢弃alpha小于等于_Progress的像素
                #else
                    float normalizedAngle = CalcRadialFading(uv);
                    color.a *= normalizedAngle > _Progress; // 设置alpha为0，使像素完全透明    
                #endif
            }

            void UpdateSurface(inout SurfaceDescription surfaceDescription, SurfaceDescriptionInputs inputs)
            {
                half3 rgb = surfaceDescription.BaseColor;
                half alpha = surfaceDescription.Alpha;
                half4 color = half4(rgb, alpha);
                ApplyRadialFading(color,inputs.uvClip.xy);
                surfaceDescription.BaseColor = color.rgb;
                surfaceDescription.Alpha = color.a;
            }

            #define UpdateSurfaceFunc UpdateSurface
            #include "UITKFunctions.hlsl"

            PackedVaryings vert(Attributes input)
            {
                PackedVaryings output = uie_custom_vert(input);
                return output;
            }

            half4 frag(PackedVaryings packedInput) : SV_Target
            {
                half4 color = uie_custom_frag(packedInput);

                // ApplyRadialFading(color, packedInput.texCoord0.xy);
                return color;
            }

            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack off
}