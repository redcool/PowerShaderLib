Shader "ShaderGraphs/UITK_RadialFade"
{
    Properties
    {
        // expose properties in the uitoolkit, so users can modify them in the material inspector or through code.

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
            
            //Properties
            CBUFFER_START(UnityPerMaterial)
                // UNITY_TEXTURE_STREAMING_DEBUG_VARS;
            CBUFFER_END

            // Functions

            void UpdateSurface(inout SurfaceDescription surfaceDescription, SurfaceDescriptionInputs inputs)
            {

            }

            // override the default UpdateSurfaceFunc defined in UITKDeclares.hlsl
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

                return color;
            }

            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack off
}