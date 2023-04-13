using System;
using UnityEngine;
using UnityEditor;
using UnityEditor.Graphs;

#if UNITY_EDITOR

namespace gtmEditor
{
    public class ParticleAllInOne : ShaderGUI
    {
        public override void OnGUI(MaterialEditor m, MaterialProperty[] properties)
        {
            m.SetDefaultGUIWidths();

            var _MainTex = ShaderGUI.FindProperty("_MainTex", properties);
            var _M_Offset_Xspeed = ShaderGUI.FindProperty("_M_Offset_Xspeed", properties);
            var _M_Offset_Yspeed = ShaderGUI.FindProperty("_M_Offset_Yspeed", properties);
            var _Color = ShaderGUI.FindProperty("_Color", properties);

            var _Dissolve_tex = ShaderGUI.FindProperty("_Dissolve_tex", properties);
            var _Dissolve = ShaderGUI.FindProperty("_Dissolve", properties);
            var _DissolveEdge = ShaderGUI.FindProperty("_DissolveEdge", properties);
            var _DissolveEdgeBlur = ShaderGUI.FindProperty("_DissolveEdgeBlur", properties);
            var _DissolveEdgeColor = ShaderGUI.FindProperty("_DissolveEdgeColor", properties);

            var _WarpTex = ShaderGUI.FindProperty("_WarpTex", properties);
            var _Warp_Intensity = ShaderGUI.FindProperty("_Warp_Intensity", properties);
            var _WarpTex_Offset_Speed = ShaderGUI.FindProperty("_WarpTex_Offset_Speed", properties);

            var _MaskTex = ShaderGUI.FindProperty("_MaskTex", properties);
            var _Mask_Offset_Xspeed = ShaderGUI.FindProperty("_Mask_Offset_Xspeed", properties);
            var _Mask_Offset_Yspeed = ShaderGUI.FindProperty("_Mask_Offset_Yspeed", properties);

            var _VertexOffset = ShaderGUI.FindProperty("_VertexOffset", properties);
            var _Strength = ShaderGUI.FindProperty("_Strength", properties);
            var _Add = ShaderGUI.FindProperty("_Add", properties);
            var _Speed = ShaderGUI.FindProperty("_Speed", properties);

            var M = ShaderGUI.FindProperty("M", properties);
            var D = ShaderGUI.FindProperty("D", properties);
            var F = ShaderGUI.FindProperty("F", properties);
            var Q = ShaderGUI.FindProperty("Q", properties);
            var V = ShaderGUI.FindProperty("V", properties);
            var C = ShaderGUI.FindProperty("C", properties);
            var _DepthRange = ShaderGUI.FindProperty("_DepthRange", properties);
            var _FresnelIntensity = ShaderGUI.FindProperty("_FresnelIntensity", properties);
            var _FresnelRange = ShaderGUI.FindProperty("_FresnelRange", properties);
            var _FresnelColor = ShaderGUI.FindProperty("_FresnelColor", properties);
            var _Cull = ShaderGUI.FindProperty("_Cull", properties);
            var _ZWrite = ShaderGUI.FindProperty("_ZWrite", properties);
            var _Blend = ShaderGUI.FindProperty("_Blend", properties);
            var _ZTest = ShaderGUI.FindProperty("_ZTest", properties);

            var _StencilRef = ShaderGUI.FindProperty("_StencilRef", properties);
            var _StencilComp = ShaderGUI.FindProperty("_StencilComp", properties);

            m.ShaderProperty(M, M.displayName);

            m.ShaderProperty(D, D.displayName);
            if (D.floatValue == 1)
            {
                m.ShaderProperty(_DepthRange, _DepthRange.displayName);
            }

            m.ShaderProperty(C, C.displayName);

            m.ShaderProperty(F, F.displayName);
            if (F.floatValue != 2)
            {
                m.ShaderProperty(_FresnelIntensity, _FresnelIntensity.displayName);
                m.ShaderProperty(_FresnelRange, _FresnelRange.displayName);
                m.ColorProperty(_FresnelColor, _FresnelColor.displayName);
            }

            m.ShaderProperty(V, V.displayName);
            m.ShaderProperty(_ZWrite, _ZWrite.displayName);
            m.ShaderProperty(_Blend, _Blend.displayName);
            m.ShaderProperty(_Cull, _Cull.displayName);
            m.ShaderProperty(_ZTest, _ZTest.displayName);

            m.ShaderProperty(_StencilRef, _StencilRef.displayName);
            m.ShaderProperty(_StencilComp, _StencilComp.displayName);

            m.ShaderProperty(Q, Q.displayName);

            m.TextureProperty(_MainTex, _MainTex.displayName);
            m.ShaderProperty(_Color, _Color.displayName);
            m.ShaderProperty(_M_Offset_Xspeed, _M_Offset_Xspeed.displayName);
            m.ShaderProperty(_M_Offset_Yspeed, _M_Offset_Yspeed.displayName);

            if (Q.floatValue == 2 || Q.floatValue == 4 || Q.floatValue == 6)
            {
                m.TextureProperty(_Dissolve_tex, _Dissolve_tex.displayName);
                m.ShaderProperty(_Dissolve, _Dissolve.displayName);
                m.ShaderProperty(_DissolveEdge, _DissolveEdge.displayName);
                m.ShaderProperty(_DissolveEdgeBlur, _DissolveEdgeBlur.displayName);
                m.ColorProperty(_DissolveEdgeColor, _DissolveEdgeColor.displayName);
            }

            if (Q.floatValue == 1 || Q.floatValue == 5 || Q.floatValue == 6)
            {
                m.TextureProperty(_WarpTex, _WarpTex.displayName);
                m.ShaderProperty(_Warp_Intensity, _Warp_Intensity.displayName);
                m.ShaderProperty(_WarpTex_Offset_Speed, _WarpTex_Offset_Speed.displayName);
            }

            if (Q.floatValue == 3 || Q.floatValue == 4 || Q.floatValue == 5 || Q.floatValue == 6)
            {
                m.TextureProperty(_MaskTex, _MaskTex.displayName);
                m.ShaderProperty(_Mask_Offset_Xspeed, _Mask_Offset_Xspeed.displayName);
                m.ShaderProperty(_Mask_Offset_Yspeed, _Mask_Offset_Yspeed.displayName);
            }

            if (V.floatValue != 1)
            {
                m.TextureProperty(_VertexOffset, _VertexOffset.displayName);
                m.ShaderProperty(_Speed, _Speed.displayName);
                m.ShaderProperty(_Strength, _Strength.displayName);
                m.ShaderProperty(_Add, _Add.displayName);

            }

            m.RenderQueueField();

#if UNITY_5_6_OR_NEWER
            m.EnableInstancingField();
            Material material = (Material)m.target;
            material.enableInstancing = true;
#endif
        }
    }
}

#endif
