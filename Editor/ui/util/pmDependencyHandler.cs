using UnityEditor;
using UnityEngine;

[InitializeOnLoad]
public class peppermintDependencyHandler
{
    static peppermintDependencyHandler()
    {
        updateDeps();

    }
    static void updateDeps()
    {
        var matguids = AssetDatabase.FindAssets("t:Material");
        AssetDatabase.StartAssetEditing();
        foreach (var guid in matguids)
        {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat.shader != null && mat.shader.name == "mintea/peppermint")
            {
                bool hasLTCGI = System.IO.File.Exists("Packages/at.pimaker.ltcgi/Shaders/LTCGI.cginc");
                if (hasLTCGI) mat.EnableKeyword("_PM_FT_LTCGI");
                else mat.DisableKeyword("_PM_FT_LTCGI");
                EditorUtility.SetDirty(mat);
            }
        }
        AssetDatabase.StopAssetEditing();
        AssetDatabase.SaveAssets();
    }
}