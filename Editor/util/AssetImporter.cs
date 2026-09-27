using UnityEditor;
using UnityEngine;

public class pmAssetImporter : AssetPostprocessor
{
    void OnPreprocessTexture()
    {
        string guid = AssetDatabase.AssetPathToGUID(assetPath);

        if (guid != "f383c55fb66a128fc8b511710bfa5acb")
            return;

        var importer = (TextureImporter)assetImporter;

        importer.wrapModeU = TextureWrapMode.Clamp;
        importer.wrapModeV = TextureWrapMode.Clamp;
        importer.wrapModeW = TextureWrapMode.Clamp;
        importer.filterMode = FilterMode.Bilinear;
    }
}
