using UnityEditor;
using UnityEngine;
using System.IO;
using Peppermint.Struct;

namespace Peppermint.Util {
    public class pmFile {
        public static bool doesDataDirExist(bool shouldCreate) {
            string root = Path.GetDirectoryName(Application.dataPath);
            string path = Path.Combine(root, "Peppermint");

            if (!Directory.Exists(path)) {
                if (shouldCreate) {
                    Directory.CreateDirectory(path);
                    return true;
                }
                return false;
            }
            return true;
        }

        public static bool doesPersistDirExist(bool shouldCreate) {
            string root = Path.GetDirectoryName(Application.dataPath);
            string path = Path.Combine(root, PATH.PERSIST_DATA);

            if (!Directory.Exists(path)) {
                if (shouldCreate) {
                    Directory.CreateDirectory(path);
                    return true;
                }
                return false;
            }
            return true;
        }

        public static bool doesShaderMetaExist() {
            string root = Path.GetDirectoryName(Application.dataPath);
            string path = Path.Combine(root, PATH.PERSIST_DATA + "/" + PATH.MATERIAL_META_FILE); 
        
            if (!File.Exists(path)) {
                return false;
            }
            return true;
        }

        public static void WriteJSON<T>(string target, T data) {
            var json = JsonUtility.ToJson(data, true);
            File.WriteAllText(target, json);
        }

        public static T ReadJSON<T>(string target) {
            if (!File.Exists(target)) {
                return default;
            }

            string json = File.ReadAllText(target);
            return JsonUtility.FromJson<T>(json);
        }
    }
}