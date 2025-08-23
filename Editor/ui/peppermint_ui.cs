#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using UnityEngine;
using UnityEditor;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text;

public class peppermint_ui : ShaderGUI
{
    private class Folder
    {
        public string name;
        public Dictionary<string, Folder> children = new Dictionary<string, Folder>();
        public List<MaterialProperty> properties = new List<MaterialProperty>();
        public string path;
        public int depth;
    }

    private class Prop
    {
        public bool SingleLineTexture = false;
    }

    private Dictionary<string, Prop> propAttributes = new Dictionary<string, Prop>();
    private static Dictionary<Material, Dictionary<string, bool>> foldoutStates = new Dictionary<Material, Dictionary<string, bool>>();

    bool PepperFoldout(ref bool expanded, string label, GUIStyle background, GUIStyle foldout, int indent)
    {
        GUILayout.Space(background.margin.top);
        Rect rect = EditorGUILayout.GetControlRect();

        Rect bgRect = rect;
        bgRect.xMin = 10 + indent;
        bgRect.xMax = EditorGUIUtility.currentViewWidth - 10;

        bgRect.xMin += background.margin.left;
        bgRect.xMax -= background.margin.right;

        bgRect.yMin -= background.padding.top;
        bgRect.yMax += background.padding.bottom;

        GUILayout.Space(background.margin.bottom);

        if (Event.current.type == EventType.Repaint)
            background.Draw(bgRect, false, false, expanded, false);

        expanded = EditorGUI.Foldout(rect, expanded, label, true, foldout);

        return expanded;
    }

    void PepperProperty(MaterialEditor editor, MaterialProperty prop, string label, GUIStyle style, int indent)
    {
        GUILayout.Space(style.margin.top);
        Rect rect = EditorGUILayout.GetControlRect();

        rect.xMin = 10 + indent;
        rect.xMax = EditorGUIUtility.currentViewWidth - 10;

        rect.xMin += style.margin.left;
        rect.xMax -= style.margin.right;

        GUILayout.Space(style.margin.bottom);

        editor.ShaderProperty(rect, prop, label);
    }

    void PepperPropertySingleLine(MaterialEditor editor, MaterialProperty prop, string label, GUIStyle style, int indent)
    {
        GUILayout.Space(style.margin.top);
        Rect rect = EditorGUILayout.GetControlRect();

        rect.xMin = 10 + indent;
        rect.xMax = EditorGUIUtility.currentViewWidth - 10;

        GUILayout.Space(style.margin.bottom);

        editor.TexturePropertyMiniThumbnail(rect, prop, label, "Select a texture...");
    }

    private static GUIStyle SectionFoldoutStyle(int indent = 0)
    {
        var style = new GUIStyle(GUI.skin.FindStyle("Foldout"))
        {
            margin = new RectOffset(indent - 5, 0, 0, 0),
            padding = new RectOffset(15, 0, 0, 0)
        };
        return style;
    }

    private static GUIStyle HelpBoxStyle(int indent = 0)
    {
        var style = new GUIStyle(GUI.skin.FindStyle("AnimItemBackground"))
        {
            margin = new RectOffset(0, 0, 5, 5),
            padding = new RectOffset(0, 0, 2, 2)
        };
        return style;
    }

    private static GUIStyle PropertyStyle(int indent = 0)
    {
        var style = new GUIStyle()
        {
            margin = new RectOffset(0, 0, 0, 0),
            padding = new RectOffset(0, 0, 0, 0)
        };
        
        return style;
    }

    private Folder BuildFolderTree(MaterialProperty[] props)
    {
        var root = new Folder{ name = "Root", path = "" };
        foreach (var prop in props)
        {
            if (prop.flags != MaterialProperty.PropFlags.HideInInspector)
            {
                string[] pathSplit = prop.displayName.Split('/');
                Folder current = root;
                for (int i = 0; i < pathSplit.Length; i++)
                {
                    string part = pathSplit[i];
                    bool isLeaf = (i == pathSplit.Length - 1);
                    current.depth = i;
                    if (isLeaf)
                        current.properties.Add(prop);
                    else
                    {
                        string childPath = (current.path == "" ? part : current.path + "/" + part);
                        if (!current.children.TryGetValue(part, out Folder child))
                        {
                            child = new Folder { name = part, path = childPath };
                            current.children[part] = child;
                        }
                        current = child;
                    }
                }
            }
        }
        return root;
    }

    private void MarkAttributes(MaterialEditor editor, MaterialProperty[] props)
    {
        Material mat = (Material)editor.target;
        var shader = mat.shader;
        int count = shader.GetPropertyCount();

        for (int i = 0; i < count; i++)
        {
            var prop = props[i];
            var name = shader.GetPropertyName(i);
            var attrs = shader.GetPropertyAttributes(i);

            if (attrs.Contains("SingleLineTexture") && !propAttributes.ContainsKey(name))
            {
                propAttributes.Add(name, new Prop{ SingleLineTexture = true });
                i++;
            }
        }
    }

    private void DrawFolder(MaterialEditor editor, Material material, Folder folder, int indent)
    {
        if (folder.name != "Root")
        {
            var states = foldoutStates[material];
            if (!states.TryGetValue(folder.path, out bool expanded))
                expanded = true;

                expanded = PepperFoldout(
                    ref expanded,
                    folder.name,
                    HelpBoxStyle(),
                    SectionFoldoutStyle(indent),
                    indent
                );


            states[folder.path] = expanded;

            if (!expanded)
                return;

            indent += 25;
        }

        int outdent = indent;

        foreach (var child in folder.children.Values)
            DrawFolder(editor, material, child, outdent);

        foreach (var prop in folder.properties)
        {
            var parsedName = prop.displayName.Split('/')[^1];
            if (propAttributes.ContainsKey(prop.name))
            {
                if (propAttributes[prop.name].SingleLineTexture == true)
                    PepperPropertySingleLine(
                        editor, 
                        prop, 
                        parsedName, 
                        PropertyStyle(indent), 
                        indent
                    );
            }
            else
                PepperProperty(
                    editor, 
                    prop, 
                    parsedName, 
                    PropertyStyle(indent), 
                    indent
                );
        }
    }

    public void ToggleKeyword(bool condition, string keyword, Material target)
    {
        if (condition && !target.IsKeywordEnabled(keyword))
            {
                target.EnableKeyword(keyword);
                EditorUtility.SetDirty(target);
            }
            else if (!condition && target.IsKeywordEnabled(keyword))
            {
                target.DisableKeyword(keyword);
                EditorUtility.SetDirty(target);
            }
    }

    private void UpdateKeywords(MaterialEditor editor, MaterialProperty[] properties, Material material)
    {
        if (material.GetTexture("_AlphaTex") != null && material.GetFloat("_pm_nk_hasalpha") == 0)
            material.SetFloat("_pm_nk_hasalpha", 1.0f);
        else if (material.GetTexture("_AlphaTex") == null && material.GetFloat("_pm_nk_hasalpha") == 1) 
            material.SetFloat("_pm_nk_hasalpha", 0.0f);
 
        float D = material.GetFloat("_DiffuseNDF");
        ToggleKeyword(D == 0, "_PM_NDF_GGX", material);
        ToggleKeyword(D == 1, "_PM_NDF_CHARLIE", material);
        float sss = material.GetFloat("_SubsurfaceEnable");
        ToggleKeyword(sss == 1, "_PM_FT_SUBSURFACE", material);
        float aso = material.GetFloat("_AnisotropicsEnable");
        ToggleKeyword(aso == 1, "_PM_FT_ANISOTROPICS", material);
    }

    private void TexCheck(bool condition, string guid, string property, MaterialProperty[] properties)
    {
        if (condition) 
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            Texture2D tex = AssetDatabase.LoadAssetAtPath<Texture2D>(path); 
            MaterialProperty prop = FindProperty(property, properties);
            prop.textureValue = tex;
        }
    }

    private void UpdateInternal(Material material, MaterialProperty[] properties) {
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
                material.GetTexture("_dfg_cloth") == null, 
                "3a4f51f7f57ed78428e302e36b886334",
                "_dfg_cloth",
                properties
            );

            TexCheck(
                material.GetTexture("_dfg") == null, 
                "ce35b977c39365343afe7f912dd94827",
                "_dfg",
                properties
            );
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material material = materialEditor.target as Material;

        UpdateInternal(material, properties);

        MarkAttributes(materialEditor, properties);

        UpdateKeywords(materialEditor, properties, material);

        if (!foldoutStates.ContainsKey(material))
            foldoutStates[material] = new Dictionary<string, bool>();

        Folder root = BuildFolderTree(properties);
        EditorGUI.indentLevel = 0;
        DrawFolder(materialEditor, material, root, 0);
        using (new GUILayout.HorizontalScope())
        {
            material.renderQueue = EditorGUILayout.IntField("Render Queue", material.renderQueue);
            if (GUILayout.Button("Reset", GUILayout.Width(60))) material.renderQueue = -1;
        }
    }
}
#endif