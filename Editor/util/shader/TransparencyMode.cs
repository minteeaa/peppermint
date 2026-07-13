using UnityEditor;
using UnityEngine;
using System.IO;
using Peppermint.Meta;
using Peppermint.Util;
using Peppermint.Struct;
using System.Collections.Generic;

namespace Peppermint.Util.Shader {
    class TransparencyMode {
        public static bool IsChanged(Material mat) {
            string guid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(mat));
            string target = Path.Combine(Path.GetDirectoryName(Application.dataPath), PATH.PERSIST_DATA + "/" + PATH.MATERIAL_META_FILE);
            MaterialStates state = new();

            if (pmFile.doesShaderMetaExist()) {
                state = state.Deserialize(pmFile.ReadJSON<MaterialMetaSerializable>(target));
            }

            float currentMode = mat.GetFloat("_AlphaMode");

            if (!state.HasFloatProp(guid, "_AlphaMode")) {
                state.SetFloatProp(guid, "_AlphaMode", currentMode);
            }

            float metaMode = state.GetFloatProp(guid, "_AlphaMode");

            pmFile.WriteJSON<MaterialMetaSerializable>(target, state.Serialize());

            if (metaMode != currentMode) {
                return true;
            }
            return false;
        }

        public static void Update(Material mat) {
            string guid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(mat));
            string target = Path.Combine(Path.GetDirectoryName(Application.dataPath), PATH.PERSIST_DATA + "/" + PATH.MATERIAL_META_FILE);

            MaterialStates state = new MaterialStates().Deserialize(pmFile.ReadJSON<MaterialMetaSerializable>(target));
            float mode = mat.GetFloat("_AlphaMode");

            if (mode == 0) {
                mat.SetInt("_BlendOp", 0);
                mat.SetInt("_SrcBlend", 1);
                mat.SetInt("_DstBlend", 0);

                mat.SetInt("_AddBlendOp", 4);
                mat.SetInt("_AddSrcBlend", 1);
                mat.SetInt("_AddDstBlend", 1);

                mat.SetInt("_BlendOpAlpha", 4);
                mat.SetInt("_SrcBlendAlpha", 1);
                mat.SetInt("_DstBlendAlpha", 1);

                mat.SetInt("_AddBlendOpAlpha", 4);
                mat.SetInt("_AddSrcBlendAlpha", 0);
                mat.SetInt("_AddDstBlendAlpha", 1);

                mat.SetInt("_ZWrite", 1);

                mat.renderQueue = 2000;
            } 
            
            if (mode == 1) {
                mat.SetInt("_BlendOp", 0);
                mat.SetInt("_SrcBlend", 1);
                mat.SetInt("_DstBlend", 0);

                mat.SetInt("_AddBlendOp", 4);
                mat.SetInt("_AddSrcBlend", 1);
                mat.SetInt("_AddDstBlend", 1);

                mat.SetInt("_BlendOpAlpha", 4);
                mat.SetInt("_SrcBlendAlpha", 1);
                mat.SetInt("_DstBlendAlpha", 1);

                mat.SetInt("_AddBlendOpAlpha", 4);
                mat.SetInt("_AddSrcBlendAlpha", 0);
                mat.SetInt("_AddDstBlendAlpha", 1);

                mat.SetInt("_ZWrite", 1);

                mat.renderQueue = 2450;
            }

            if (mode == 2) {
                mat.SetInt("_BlendOp", 0);
                mat.SetInt("_SrcBlend", 5);
                mat.SetInt("_DstBlend", 10);

                mat.SetInt("_AddBlendOp", 4);
                mat.SetInt("_AddSrcBlend", 5);
                mat.SetInt("_AddDstBlend", 1);

                mat.SetInt("_BlendOpAlpha", 4);
                mat.SetInt("_SrcBlendAlpha", 1);
                mat.SetInt("_DstBlendAlpha", 1);

                mat.SetInt("_AddBlendOpAlpha", 4);
                mat.SetInt("_AddSrcBlendAlpha", 0);
                mat.SetInt("_AddDstBlendAlpha", 1);

                mat.SetInt("_ZWrite", 1);

                mat.renderQueue = 2460;
            }

            if (mode == 3) {
                mat.SetInt("_BlendOp", 0);
                mat.SetInt("_SrcBlend", 1);
                mat.SetInt("_DstBlend", 10);

                mat.SetInt("_AddBlendOp", 4);
                mat.SetInt("_AddSrcBlend", 1);
                mat.SetInt("_AddDstBlend", 1);

                mat.SetInt("_BlendOpAlpha", 4);
                mat.SetInt("_SrcBlendAlpha", 1);
                mat.SetInt("_DstBlendAlpha", 1);

                mat.SetInt("_AddBlendOpAlpha", 4);
                mat.SetInt("_AddSrcBlendAlpha", 0);
                mat.SetInt("_AddDstBlendAlpha", 1);

                mat.SetInt("_ZWrite", 0);

                mat.renderQueue = 3000;
            }

            state.SetFloatProp(guid, "_AlphaMode", mode);
            pmFile.WriteJSON<MaterialMetaSerializable>(target, state.Serialize());
            EditorUtility.SetDirty(mat);
        }
    }
}