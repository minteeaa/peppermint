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

    private static GUIStyle FoldoutStyle()
    {
        var style = new GUIStyle(GUI.skin.FindStyle("Foldout"))
        {
            margin = new RectOffset(0, 0, 0, 0),
            padding = new RectOffset(15, 0, 0, 0)
        };
        style.normal = GUI.skin.FindStyle("LargeLabel").normal;
        style.fontSize = 13;

        return style;
    }

    private static GUIStyle HelpBoxStyle(int indent = 0)
    {
        var style = new GUIStyle()
        {
            margin = new RectOffset(indent, 0, 0, 0),
            padding = new RectOffset(0, 3, 0, 3)
        };
        
        return style;
    }

    private static GUIStyle Wrapper()
    {
        var style = new GUIStyle()
        {
            margin = new RectOffset(0, 0, 0, 0),
            padding = new RectOffset(0, 0, 0, 0)
        };
        
        return style;
    }

    private static GUIStyle PropertyStyle(int indent = 0)
    {
        var style = new GUIStyle()
        {
            margin = new RectOffset(indent, 0, 0, 0),
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

            using (new GUILayout.VerticalScope(Wrapper()))
                using (new GUILayout.HorizontalScope(HelpBoxStyle(indent)))
                    expanded = EditorGUILayout.Foldout(expanded, folder.name, true, FoldoutStyle());

            states[folder.path] = expanded;

            if (!expanded)
                return;
        }

        int outdent = indent + 15;

        foreach (var child in folder.children.Values)
            if (child.depth == 1) 
                DrawFolder(editor, material, child, indent);
            else
                DrawFolder(editor, material, child, outdent);

        foreach (var prop in folder.properties)
        {
            var parsedName = prop.displayName.Split('/')[^1];
            using (new GUILayout.VerticalScope(Wrapper()))
                using (new GUILayout.HorizontalScope(PropertyStyle(indent)))
                    if (propAttributes.ContainsKey(prop.name))
                    {
                        if (propAttributes[prop.name].SingleLineTexture == true)
                            editor.TexturePropertySingleLine(new GUIContent(parsedName), prop);
                    }
                    else
                        editor.ShaderProperty(prop, parsedName);
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
        bool hasAlpha = material.GetTexture("_AlphaTex") != null;
        ToggleKeyword(hasAlpha, "_HAS_ALPHA_TEX", material);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material material = materialEditor.target as Material;

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