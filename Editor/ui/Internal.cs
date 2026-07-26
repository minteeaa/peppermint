using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text;
using Peppermint.Util;

namespace Peppermint.UI {

    public class Internal
    {
        public void TexCheck(bool condition, string guid, string property, MaterialProperty[] properties)
        {
            if (condition) 
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                Texture2D tex = AssetDatabase.LoadAssetAtPath<Texture2D>(path); 
                foreach (MaterialProperty prop in properties) {
                    if (prop.name == property) {
                        prop.textureValue = tex;
                    }
                }
            }
        }

        public void UpdateInternal(Material material, MaterialProperty[] properties) {
                TexCheck(
                    material.GetTexture("_ditherPattern") == null, 
                    "481eb725641632748b7be205a1f60124",
                    "_ditherPattern",
                    properties
                );

                TexCheck(
                    material.GetTexture("_samplerDefault") == null, 
                    "1428608754793fb43b394b86fe5c8e20",
                    "_samplerDefault",
                    properties
                );
                    
                TexCheck(
                    material.GetTexture("_dfg") == null, 
                    "f383c55fb66a128fc8b511710bfa5acb",
                    "_dfg_",
                    properties
                );

                TexCheck(
                    material.GetTexture("_dfg").ToString() != "pm_dfg", 
                    "f383c55fb66a128fc8b511710bfa5acb",
                    "_dfg",
                    properties
                );
        }

        public void UpdateTextures()
        {
            string[] materialGuids = AssetDatabase.FindAssets("t:Material");
            AssetDatabase.StartAssetEditing();
            foreach (string guid in materialGuids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                Material mat = AssetDatabase.LoadAssetAtPath<Material>(path);
                if (mat != null) {
                    if (mat.shader != null && mat.shader.name == "mintea/peppermint")
                    {
                        MaterialProperty[] properties = MaterialEditor.GetMaterialProperties(new[] { mat });
                        UpdateInternal(mat, properties);
                        EditorUtility.SetDirty(mat);
                    }
                }
            }
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
        }
    }
}