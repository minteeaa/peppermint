using UnityEditor;
using UnityEngine;
using System.IO;
using Peppermint.Util;

namespace Peppermint.Util {

    [InitializeOnLoad]
    public class Dependencies
    {
        static Dependencies()
        {
            UpdateLTCGI();
        }

        static void UpdateLTCGI()
        {
            var matguids = AssetDatabase.FindAssets("t:Material");
            bool hasLTCGI = File.Exists("Packages/at.pimaker.ltcgi/Shaders/LTCGI.cginc");
            AssetDatabase.StartAssetEditing();
            foreach (var guid in matguids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
                if (mat.shader != null && mat.shader.name == "mintea/peppermint")
                {
                    if (hasLTCGI) mat.EnableKeyword("_PM_FT_LTCGI");
                    else mat.DisableKeyword("_PM_FT_LTCGI");
                    EditorUtility.SetDirty(mat);
                }
            }
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
        }
    }
}