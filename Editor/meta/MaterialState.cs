using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
using Peppermint.Struct;

namespace Peppermint.Meta {
    [Serializable]
    public class MaterialMetaSerializable {
        public List<MaterialMeta> meta = new();
        public int version = 1;
    }

    public class MaterialStates {

        public Dictionary<string, Dictionary<string, float>> db = new();

        public bool HasFloatProp(string guid, string name) {
            if (db.TryGetValue(guid, out var props)) {
                if (props.ContainsKey(name)) return true;
            }
            return false;
        }

        public float GetFloatProp(string guid, string name) {
            if (db.TryGetValue(guid, out var props) &&
                props.TryGetValue(name, out float val)) {
                return val;
            }
            return 0;
        }

        public void SetFloatProp(string guid, string name, float value) {
            if (!db.ContainsKey(guid)) db[guid] = new Dictionary<string, float>();
            db[guid][name] = value;
        }

        public MaterialMetaSerializable Serialize() {
            MaterialMetaSerializable states = new();
            foreach (var (guid, props) in db) {
                MaterialMeta entry = new();
                entry.guid = guid;
                foreach (var (prop, val) in props) {
                    entry.props.Add(new MaterialMeta.Prop()
                        { name = prop, value = val });
                }
                states.meta.Add(entry);
            }
            return states;
        }

        public MaterialStates Deserialize(MaterialMetaSerializable json) {
            foreach (var entry in json.meta) {
                db[entry.guid] = new Dictionary<string, float>();
                foreach (var prop in entry.props) {
                    db[entry.guid][prop.name] = prop.value;
                }
            }
            return this;
        }
    }
}