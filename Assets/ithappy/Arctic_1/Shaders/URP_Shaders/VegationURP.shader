Shader "ithappy/VegationURP"
{
    Properties
    {
        [Header(Color)]
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Header(Sine)]
        _Frequency ("Frequency", float) = 1
        _Amplitude ("Amplitude", vector) = (1, 1, 0, 0)

        [Header(Influence)]
        _MinY ("MinY", float) = 0.3
        _MaxY ("MaxY", float) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipline"="Universal" 
            "Queue"="Geometry"
        }

        Pass
        {
            Name "ForwardLit"

            tags
            {
                "LightMode" = "UniversalForward" 
            }

            HLSLPROGRAM

            #pragma vertex VertexFunction
            #pragma fragment FragmentFunction

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            struct Attributes
            {
                float4 position_os : POSITION;
                float3 normal_os : NORMAL;
                float2 st : TEXCOORD0;
            };

            struct Interpolators
            {
                float2 st : TEXCOORD0;
                float3 normal_ws : TEXCOORD1;
                float3 viewVector_ws : TEXCOORD2;
                float3 position_ws : TEXCOORD3;

                float4 position_cs : SV_POSITION;
            };

            uniform half _Frequency;
            uniform half2 _Amplitude;

            uniform half _MinY;
            uniform half _MaxY;

            void VertexFunction(in Attributes input, out Interpolators output)
            {
                float4 position_ws = mul(UNITY_MATRIX_M, input.position_os);

                float inflence = (clamp(input.position_os.y, _MinY, _MaxY) - _MinY) / (_MaxY - _MinY);
                position_ws.xz += inflence * (_Amplitude + sin(_Time.y * _Frequency) * _Amplitude);

                output.st = input.st;
                output.normal_ws = TransformObjectToWorldNormal(input.normal_os);
                output.viewVector_ws = GetCameraPositionWS().xyz - position_ws.xyz;
                output.position_ws = position_ws.xyz;
                output.position_cs = mul(unity_MatrixVP, position_ws);
            }

            #pragma shader_feature _RECEIVE_SHADOWS_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // v11:
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION

            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            uniform sampler2D _MainTex;
            uniform half4 _Color;

            uniform half _Glossiness;
            uniform half _Metallic;

            void InitializeSurfaceData(in Interpolators input, out SurfaceData surfaceData)
            {
                surfaceData = (SurfaceData)0;

	            surfaceData.albedo = tex2D(_MainTex, input.st).rgb * _Color.rgb;
                surfaceData.specular = half3(0, 0, 0);
                surfaceData.metallic = _Metallic;
                surfaceData.smoothness = _Glossiness;
                surfaceData.emission = half3(0, 0, 0);
                surfaceData.occlusion = 1;
                surfaceData.normalTS = half3(0, 0, 1);
                surfaceData.alpha = 1;
            }

            void InitializeInputData(in Interpolators input, out InputData inputData) 
            {
	            inputData = (InputData)0;
                
                inputData.positionWS = input.position_ws;
                inputData.normalWS = normalize(input.normal_ws);
                inputData.positionCS = input.position_cs;
                inputData.viewDirectionWS = normalize(input.viewVector_ws);

                half4 shadowCoord = TransformWorldToShadowCoord(input.position_ws);
                inputData.shadowCoord = shadowCoord;
            }

            void FragmentFunction(in Interpolators input, out half4 color : SV_Target)
            {
                SurfaceData surfaceData;
                InitializeSurfaceData(input, surfaceData);

                InputData inputData;
                InitializeInputData(input, inputData);

                color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
            }

            ENDHLSL
        }

        Pass 
        {
	        Name "DepthOnly"
	        Tags { "LightMode"="DepthOnly" }

	        ColorMask 0
	        ZWrite On
	        ZTest LEqual

	        HLSLPROGRAM
	        #pragma vertex DisplacedDepthOnlyVertex
	        #pragma fragment DepthOnlyFragment

	        #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

	        #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
	        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
	        #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            
            uniform half _Frequency;
            uniform half2 _Amplitude;

            uniform half _MinY;
            uniform half _MaxY;

            void DisplacedDepthOnlyVertex(Attributes input, out Varyings output) 
            {
	            output = (Varyings)0;
	            UNITY_SETUP_INSTANCE_ID(input);
	            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float4 position_ws = mul(UNITY_MATRIX_M, input.position);

                float inflence = (clamp(input.position.y, _MinY, _MaxY) - _MinY) / (_MaxY - _MinY);
                position_ws.xz += inflence * (_Amplitude + sin(_Time.y * _Frequency) * _Amplitude);

	            output.positionCS = TransformWorldToHClip(position_ws.xyz);
            }

	        ENDHLSL
        }

        Pass 
        {
	        Name "ShadowCaster"
	        Tags { "LightMode"="ShadowCaster" }

	        ZWrite On
	        ZTest LEqual

	        HLSLPROGRAM
	        #pragma vertex DisplacedShadowPassVertex
	        #pragma fragment ShadowPassFragment

	        #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

	        #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
	        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
	        #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            
            uniform half _Frequency;
            uniform half2 _Amplitude;

            uniform half _MinY;
            uniform half _MaxY;

            void DisplacedShadowPassVertex(Attributes input, out Varyings output) 
            {
	            output = (Varyings)0;
	            UNITY_SETUP_INSTANCE_ID(input);
	            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float4 position_ws = mul(UNITY_MATRIX_M, input.positionOS);

                float inflence = (clamp(input.positionOS.y, _MinY, _MaxY) - _MinY) / (_MaxY - _MinY);
                position_ws.xz += inflence * (_Amplitude + sin(_Time.y * _Frequency) * _Amplitude);

	            output.positionCS = TransformWorldToHClip(position_ws.xyz);
            }


	        ENDHLSL
        }
    }
}
