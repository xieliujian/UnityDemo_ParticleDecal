Shader  "gtm/Effect/ParticleAllInOne"
{
    // 源项目链接 https://github.com/ColinLeung-NiloCat/UnityURPUnlitScreenSpaceDecalShader

    Properties
    {
        [KeywordEnum(Mesh, Particle)] M("Mesh & Particle", Float)= 1
        [KeywordEnum(DepthOff, DepthOn)] D("Depth", Float)= 0
        _DepthRange("    DepthRange",float)= 1
        [KeywordEnum(FresnelColor, FresnelBlur, FresnelOff)] F("Fresnel", Float) = 2
        _FresnelIntensity("     FresnelIntensity",Range(0,5))=0
        _FresnelRange("     FresnelRange",Range(0,10))=5
        [HDR]_FresnelColor("     FresnelColor",Color)= (1,1,1,1)
        [KeywordEnum(V_ON, V_OFF)] V("VertexOffset", Float)= 1
        [KeywordEnum(DECAL_OFF, DECAL_ON)] C("Decal", Float) = 0
        [Toggle]_ZWrite("ZWrite", Float)= 0
        [Enum(One,1,OneMinusSrcAlpha,10)] _Blend ("Blend Mode", Float)= 1 
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float)= 2
        
        [Header(Stencil Masking)]
        //https://docs.unity3d.com/ScriptReference/Rendering.CompareFunction.html
        _StencilRef("_StencilRef", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("_StencilComp (default = Disable) _____Set to NotEqual if you want to mask by specific _StencilRef value, else set to Disable", Float) = 0 //0 = disable
        
        [Header(ZTest)]
        //https://docs.unity3d.com/ScriptReference/Rendering.CompareFunction.html
        //default need to be Disable, because we need to make sure decal render correctly even if camera goes into decal cube volume, although disable ZTest by default will prevent EarlyZ (bad for GPU performance)
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("_ZTest (default = LessEqual) _____to improve GPU performance, Set to LessEqual if camera never goes into cube volume, else set to Disable", Float) = 4 //4 = LessEqual

        [Space]
        [Header(FX_Sampler2D)]
        [KeywordEnum(BasicColor, Warp, Dissolve, BasicColor_Mask, Dissolve_Mask, Warp_Mask, Dissolve_Warp_Mask )] Q("FX Mode", Float) = 0 
        _MainTex ("MainTex //Offset.xy = Custom1.xy", 2D)= "white" {}

        [HDR]_Color ("     MainColor",Color)= (1,1,1,1)
        _M_Offset_Xspeed("     M_Offset_Xspeed",Float)=0
        _M_Offset_Yspeed("     M_Offset_Yspeed",Float)=0
        
        [Header(DissolveTex)]
        _Dissolve_tex ("DissolveTex",2D)= "white" {}
        _Dissolve ("     Dissolve //= Coustom1.z",Range(0,1))= 0
        _DissolveEdge("     DissolveEdge //= Custom1.w",Range(0,0.2))= 0
        _DissolveEdgeBlur ("     DissolveEdgeBlur",Range(0.5,1)) = 0.5
        [HDR]_DissolveEdgeColor ("     DissolveEdgeColor",Color)= (1,1,1,1)

        [Header(WarpTex)]
        _WarpTex ("WarpTex //Offset.xy= Custom2.xy",2D)= "white" {}
        _Warp_Intensity("     Warp_Intensity",Float)= 0
        _WarpTex_Offset_Speed("     WarpTex_Offset_Speed",Float) = 0
        [Header(MaskTex)]
        _MaskTex ("MaskTex //Offset.xy= Custom2.zw",2D)= "white" {} 
        _Mask_Offset_Xspeed("     Mask_Offset_Xspeed",Float)=0
        _Mask_Offset_Yspeed("     Mask_Offset_Yspeed",Float)=0    

        [Header(VertexTex)]
        _VertexOffset("VertexTex", 2D) = "white" {}
		_Strength("     Strength", Float) = 0
		_Add("     Add", Float) = 0   
        _Speed("     Speed",Float) = 0
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #pragma target 3.0
        ENDHLSL

        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            WriteMask 255
            ReadMask 255
            Pass Keep
            Fail Keep
            ZFail Keep
        }
        
        Blend SrcAlpha [_Blend]
        Cull [_Cull]
        ZWrite [_ZWrite]
        ZTest [_ZTest]
        
        Pass
        { 

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #define REQUIRE_DEPTH_TEXTURE 1

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile  D_DEPTHOFF D_DEPTHON
            #pragma multi_compile  Q_BASICCOLOR Q_DISSOLVE_MASK Q_WARP Q_DISSOLVE_WARP_MASK Q_BASICCOLOR_MASK Q_WARP_MASK Q_DISSOLVE
            #pragma multi_compile  M_MESH M_PARTICLE 
            #pragma multi_compile  F_FRESNELCOLOR  F_FRESNELBLUR  F_FRESNELOFF
            #pragma multi_compile  V_V_ON V_V_OFF
            #pragma multi_compile  C_DECAL_OFF C_DECAL_ON
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            
            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 uv : TEXCOORD0;
                float4 uv1 : TEXCOORD1;  
                float4 uv2 : TEXCOORD2;
                float4 uv3 :TEXCOORD6;
                float4 vertexColor : COLOR;
            };
            
            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                float3 Normal: NORMAL;
                float4 uv : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 uv2 : TEXCOORD2; 
                float4 uv3 :TEXCOORD6;
                float3 ViewDir : TEXCOORD4;
                float4 SP : TEXCOORD5;

                #if C_DECAL_ON
                float4 screenUV : TEXCOORD3;
                float3 ray : TEXCOORD7;
                #endif

                float4 vertexColor : COLOR;
            };

            sampler2D _MainTex, _MaskTex, _Dissolve_tex, _WarpTex, _VertexOffset;

            CBUFFER_START( UnityPerMaterial )
            float4x4 _World2ObjMatrix;
            float _Dissolve, _Warp_Intensity, _DissolveEdge, _DissolveEdgeBlur, _FresnelIntensity, _FresnelRange, _M_Offset_Xspeed, _M_Offset_Yspeed, _Mask_Offset_Xspeed, _Mask_Offset_Yspeed;
            float _Strength, _Add, _Speed, _WarpTex_Offset_Speed, _DepthRange ;
            float4 _MainTex_ST, _Color, _WarpTex_ST, _Dissolve_tex_ST, _MaskTex_ST, _VertexOffset_ST;           
            float3 _DissolveEdgeColor, _FresnelColor ;
            CBUFFER_END

            void CalcUV(inout VertexOutput o, float4 uv, float4 uv1, float4 uv2, float4 uv3)
            {
                o.uv.xy = uv.xy * _MainTex_ST.xy + _MainTex_ST.zw + _Time.x * float2(_M_Offset_Xspeed, _M_Offset_Yspeed); //Maintexoffset
                float2 Warp_UV_Offset = uv.xy;
                float2 Mask_UV_Offset = uv.xy;

                //------------------------------------------------------------------------------------------------------------------
            #if M_PARTICLE
                o.uv.xy += uv.zw;    //v.uv.zw ，Particle_System: CustomData
                Warp_UV_Offset += uv2.xy;
                Mask_UV_Offset += uv2.zw;
            #endif
                //------------------------------------------------------------------------------------------------------------------

            #if Q_WARP 
                o.uv2.xy = (uv.xy + uv2.xy) * _WarpTex_ST.xy + _WarpTex_ST.zw + _Time.x * float2(_WarpTex_Offset_Speed, _WarpTex_Offset_Speed); //扭曲结果后的uv偏移
            #endif

            #if Q_DISSOLVE_WARP_MASK 
                o.uv2.xy = (uv.xy + uv2.xy) * _WarpTex_ST.xy + _WarpTex_ST.zw + _Time.x * float2(_WarpTex_Offset_Speed, _WarpTex_Offset_Speed);
                o.uv3.xy = (Mask_UV_Offset)*_MaskTex_ST.xy + _MaskTex_ST.zw + _Time.x * float2(_Mask_Offset_Xspeed, _Mask_Offset_Yspeed);
            #endif

            #if Q_WARP_MASK  
                o.uv2.xy = (Warp_UV_Offset)*_WarpTex_ST.xy + _WarpTex_ST.zw + _Time.x * float2(_WarpTex_Offset_Speed, _WarpTex_Offset_Speed);
                o.uv3.xy = (Mask_UV_Offset)*_MaskTex_ST.xy + _MaskTex_ST.zw + _Time.x * float2(_Mask_Offset_Xspeed, _Mask_Offset_Yspeed);
            #endif

            #if Q_BASICCOLOR_MASK || Q_DISSOLVE_MASK
                o.uv2.xy = (uv.xy + uv2.zw) * _MaskTex_ST.xy + _MaskTex_ST.zw + _Time.x * float2(_Mask_Offset_Xspeed, _Mask_Offset_Yspeed); //遮罩的uv偏移
            #endif
            }
            
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o=(VertexOutput) 0;

//-------------------------------------------------ViewDir&Normal---------------------------------------------------
                #if F_FRESNELBLUR || F_FRESNELCOLOR 
                float3 lwWorldPos = TransformObjectToWorld(v.vertex.xyz);
				o.ViewDir = _WorldSpaceCameraPos.xyz  - lwWorldPos;   //指向摄像机向量
                o.Normal = TransformObjectToWorldNormal(v.normal);  
                #endif
//-------------------------------------------------End--------------------------------------------------------------

//-------------------------------------------------VertexOffset-----------------------------------------------------
                #if V_V_ON
                float V_speed = _Time.x * _Speed;
                float2 uv_VertexOffset = v.uv.xy * _VertexOffset_ST.xy + _VertexOffset_ST.zw + V_speed;
				float3 vertexValue = ( ( ( tex2Dlod( _VertexOffset, float4( uv_VertexOffset, 0, 0.0) ).r  * _Strength ) + _Add ) * v.normal );
                v.vertex.xyz += vertexValue;
                #endif
//----------------------------------------------------End-----------------------------------------------------------

                o.vertexColor = v.vertexColor;
                o.uv1 = v.uv1;
                o.uv2 = v.uv2;      
                o.uv3 = v.uv3;


                #ifndef C_DECAL_ON

                CalcUV(o, v.uv, v.uv1, v.uv2, v.uv3);

                #endif

                o.clipPos = TransformObjectToHClip(v.vertex.xyz);

                #if D_DEPTHON
                o.SP = ComputeScreenPos(o.clipPos);
                #endif

                #if C_DECAL_ON
                o.screenUV = ComputeScreenPos(o.clipPos);
                o.ray = TransformWorldToView(TransformObjectToWorld(v.vertex.xyz).xyz) * float3(-1, -1, 1);
                #endif

                return o;
            }

            float4 frag(VertexOutput i) : SV_Target
            {
                float3 DepthTex = float3(1,1,1);

                #if D_DEPTHON
                float4 screenPos = i.SP;
                float4 screenPosNorm = screenPos / screenPos.w;
                screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
                float screenDepth9 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( screenPosNorm.xy ),_ZBufferParams);
                float distanceDepth9 =  abs( ( screenDepth9 - LinearEyeDepth( screenPosNorm.z,_ZBufferParams ) ) / _DepthRange );
                DepthTex = (saturate(distanceDepth9 ) ).xxx  ;  //这里不saturate会出现负值。
                #endif

                #if C_DECAL_ON

                i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
                float2 screenuv = i.screenUV.xy / i.screenUV.w;
                float screendepth = SampleSceneDepth(screenuv);         
                screendepth = Linear01Depth(screendepth, _ZBufferParams);   // 要转换成线性的深度值 Linear01Depth在common.hlsl里面

                float4 decal_vpos = float4(i.ray * screendepth, 1);
                float3 decal_wpos = mul(unity_CameraToWorld, decal_vpos).xyz;

                float3 decal_opos = mul(_World2ObjMatrix, float4(decal_wpos, 1.0)).xyz;
                clip(float3(0.5, 0.5, 0.5) - abs(decal_opos));

                i.uv.xy = decal_opos.xz + 0.5;     // 转换到 [0,1] 区间

                CalcUV(i, i.uv, i.uv1, i.uv2, i.uv3);

                #endif

//--------------------------fresnel-------------------------------------------------------------------------
                #if F_FRESNELBLUR || F_FRESNELCOLOR
                    float3 V = normalize(i.ViewDir);
                    float3 N = normalize(i.Normal);
                    float F =  (dot(N,V) );                    
                    float fresnelPow = saturate(  _FresnelIntensity * pow( abs(1.0 - F), _FresnelRange ) );
                    float ReverseFersnel = max(0, 1 - fresnelPow);
                    float3 Fresnel = (fresnelPow).xxx * _FresnelColor;  
                #endif
//--------------------------fresnel_END----------------------------------------------------------------------
                float4 finalColor;

                #if Q_DISSOLVE_WARP_MASK || Q_WARP || Q_WARP_MASK            
                    float4 Warp_tex_color = tex2D(_WarpTex,i.uv2.xy);
                    float4 Warp = i.uv +(Warp_tex_color.r * _Warp_Intensity ) ;     
                    float4 MainTex_color = tex2D(_MainTex, Warp.xy);
                #endif    
//---------------------------------------------------------------------------------------------------------- i.uv2改为warp图uv
                #if  Q_WARP_MASK
                    float4 MaskTex_color = tex2D(_MaskTex,( ( (i.uv3.xy+ (Warp_tex_color.r * _Warp_Intensity ) ).xy  ) * _MaskTex_ST.xy + _MaskTex_ST.zw + _Time.x*float2(_Mask_Offset_Xspeed,_Mask_Offset_Yspeed))  ); // Tiling & offset                                                        
                    MainTex_color.a *= MaskTex_color.r;
                #endif
//----------------------------------------------------------------------------------------------------------
                 #if Q_BASICCOLOR_MASK
                    float4 MainTex_color = tex2D(_MainTex,i.uv.xy); 
                    float4 MaskTex_color = tex2D(_MaskTex,i.uv2.xy);
                    MainTex_color.a *= MaskTex_color.r;                     
                #endif
//----------------------------------------------------------------------------------------------------------
                #if Q_BASICCOLOR || Q_DISSOLVE_MASK || Q_DISSOLVE     
                    float4 MainTex_color = tex2D(_MainTex,i.uv.xy);
                #endif
//----------------------------------------------------------------------------------------------------------                                
                finalColor= MainTex_color;               
//----------------------------------------------------------------------------------------------------------  
                #if Q_DISSOLVE_MASK                   
                    float4 Dissolve_color = tex2D(_Dissolve_tex, (i.uv.xy * _Dissolve_tex_ST.xy + _Dissolve_tex_ST.zw)  );
                    float4 MaskTex_color = tex2D(_MaskTex,i.uv2.xy);
                #endif

                #if Q_DISSOLVE
                    float4 Dissolve_color = tex2D(_Dissolve_tex, (i.uv.xy * _Dissolve_tex_ST.xy + _Dissolve_tex_ST.zw)  );
                #endif

                #if Q_DISSOLVE_WARP_MASK   
                    float4 Dissolve_color = tex2D(_Dissolve_tex, (Warp.xy * _Dissolve_tex_ST.xy + _Dissolve_tex_ST.zw)  );
                    float4 MaskTex_color = tex2D(_MaskTex, i.uv3.xy+ (Warp_tex_color.r * _Warp_Intensity ));
                #endif
//----------------------------------------------------------------------------------------------------------
                #if Q_DISSOLVE_MASK || Q_DISSOLVE_WARP_MASK  
                    float3 emissive = (finalColor.rgb*_Color.rgb);
                    #if M_PARTICLE
                        saturate(_Dissolve += i.uv1.z );//Particle System: CustomData   i.uv1.z
                        saturate(_DissolveEdge += i.uv1.w   );//Particle System: CustomData  i.uv1.w
                    #endif
                    float Opacity_max =  saturate(Dissolve_color.r + 1 + (_Dissolve*-2) );
                    float Opacity_min =  saturate(Dissolve_color.r + 1 + (_Dissolve + _DissolveEdge)*-2 );
                    float finalopacity = smoothstep((1 -_DissolveEdgeBlur), _DissolveEdgeBlur, Opacity_max) ;
                    float finalopacity_Edge = (finalopacity- smoothstep((1 -_DissolveEdgeBlur), _DissolveEdgeBlur, Opacity_min))* MainTex_color.r ;//计算亮边
                    emissive.rgb= _DissolveEdgeColor* finalopacity_Edge+ emissive.rgb;
                    
                    #if F_FRESNELBLUR
                        finalColor = float4(emissive* i.vertexColor.rgb , finalopacity* MainTex_color.a * MaskTex_color.r) * _Color.a* i.vertexColor.a* ReverseFersnel* DepthTex.r;                   
                    #elif F_FRESNELCOLOR
                        finalColor = float4(emissive* i.vertexColor.rgb  + Fresnel, finalopacity* MainTex_color.a * MaskTex_color.r ) * _Color.a* i.vertexColor.a* DepthTex.r;
                    #else
                        finalColor = float4(emissive* i.vertexColor.rgb, finalopacity* MainTex_color.a * MaskTex_color.r ) * _Color.a* i.vertexColor.a* DepthTex.r;
                    #endif
                    return finalColor; 
                #endif
//----------------------------------------------------------------------------------------------------------
                #if Q_DISSOLVE
                    float3 emissive = (finalColor.rgb*_Color.rgb);
                    #if M_PARTICLE
                        saturate(_Dissolve += i.uv1.z );//Particle System: CustomData   i.uv1.z
                        saturate(_DissolveEdge += i.uv1.w   );//Particle System: CustomData  i.uv1.w
                    #endif
                    float Opacity_max =  saturate(Dissolve_color.r + 1 + (_Dissolve*-2) );
                    float Opacity_min =  saturate(Dissolve_color.r + 1 + (_Dissolve + _DissolveEdge)*-2 );
                    float finalopacity = smoothstep((1 -_DissolveEdgeBlur), _DissolveEdgeBlur, Opacity_max) ;
                    float finalopacity_Edge = (finalopacity- smoothstep((1 -_DissolveEdgeBlur), _DissolveEdgeBlur, Opacity_min))* MainTex_color.r ;//计算亮边
                    emissive.rgb= _DissolveEdgeColor* finalopacity_Edge+ emissive.rgb;
                    
                    #if F_FRESNELBLUR
                        finalColor = float4(emissive* i.vertexColor.rgb , finalopacity* MainTex_color.a ) * _Color.a* i.vertexColor.a* ReverseFersnel* DepthTex.r;                   
                    #elif F_FRESNELCOLOR
                        finalColor = float4(emissive* i.vertexColor.rgb  + Fresnel, finalopacity* MainTex_color.a ) * _Color.a* i.vertexColor.a* DepthTex.r;
                    #else
                        finalColor = float4(emissive* i.vertexColor.rgb, finalopacity* MainTex_color.a ) * _Color.a* i.vertexColor.a* DepthTex.r;
                    #endif
                    return finalColor; 
                #endif
//----------------------------------------------------------------------------------------------------------
                finalColor.rgb *= _Color.rgb;
                float3 color_a = ((finalColor.rgb) * i.vertexColor.rgb ) ;

                #if F_FRESNELBLUR
                    return  float4(color_a , i.vertexColor.a * _Color.a * MainTex_color.a * ReverseFersnel* DepthTex.r );
                #elif F_FRESNELCOLOR
                    return  float4(color_a + Fresnel, i.vertexColor.a *_Color.a * MainTex_color.a* DepthTex.r );
                #endif

                return float4(color_a , i.vertexColor.a *_Color.a * MainTex_color.a* DepthTex.r );
            }

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "gtmEditor.ParticleAllInOne"
}
