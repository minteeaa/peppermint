using System;
using System.Collections.Generic;

namespace Peppermint.Struct {
    [Serializable]
    public class MaterialMeta {
        public string guid;
        public List<Prop> props = new();

        [Serializable]
        public class Prop {
            public string name; 
            public float value;
        } 
    }
}