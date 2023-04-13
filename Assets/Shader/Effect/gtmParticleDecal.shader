Shader "gtm/Effect/ParticleDecal"
{
	Properties
	{
		_MainTex ("Decal Texture", 2D) = "white" {}
		[HDR]_Color("_Color",color) = (1,1,1,1)

		[Header(Stencil Masking)]
		//https://docs.unity3d.com/ScriptReference/Rendering.CompareFunction.html
		_StencilRef("_StencilRef", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("_StencilComp (default = Disable) _____Set to NotEqual if you want to mask by specific _StencilRef value, else set to Disable", Float) = 0 //0 = disable		
	}
	
	SubShader
	{
		Tags{ "Queue"="Transparent" }
		
		Pass
		{
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			ZTest False
			Cull Off

			Stencil
			{
				Ref[_StencilRef]
				Comp[_StencilComp]
				WriteMask 255
				ReadMask 255
				Pass Keep
				Fail Keep
				ZFail Keep
			}

			HLSLPROGRAM
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"		

			float4 _Color;

			float4x4 _World2ObjMatrix;
			
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 vertexcolor : COLOR;
				//UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 screenUV : TEXCOORD0;
				float3 ray : TEXCOORD1;
				float4 vertexcolor : COLOR;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertexcolor = v.vertexcolor;
				o.pos = TransformObjectToHClip (v.vertex.xyz);
				o.screenUV = ComputeScreenPos (o.pos);
				o.ray = TransformWorldToView(TransformObjectToWorld(v.vertex.xyz).xyz ) * float3(-1,-1,1);
				return o;
			}

			sampler2D _MainTex;
			float4 frag(v2f i) : SV_Target
			{
				i.ray = i.ray * (_ProjectionParams.z / i.ray.z);

				float2 uv = i.screenUV.xy / i.screenUV.w;
				float depth = SampleSceneDepth(uv);

				// 要转换成线性的深度值 Linear01Depth在 common.hlsl里面
				depth = Linear01Depth (depth, _ZBufferParams);

				float4 vpos = float4(i.ray * depth, 1);
				float3 wpos = mul (unity_CameraToWorld, vpos).xyz;

				//float3 opos = TransformWorldToObject (wpos).xyz;
				float3 opos = mul(_World2ObjMatrix, float4(wpos, 1.0)).xyz;

				clip (float3(0.5,0.5,0.5) - abs(opos));

				// 转换到 [0,1] 区间 //
				float2 texUV = opos.xz + 0.5;

				float4 miantex = tex2D (_MainTex, texUV);

				float3 col = miantex.rgb* _Color.rgb* i.vertexcolor.rgb;
				float alpha = miantex.a* _Color.a* i.vertexcolor.a;

				return float4(col,alpha);
			}
			ENDHLSL
		}
	}

	Fallback Off
}
