<div align=center class=flex>
    <img height="125" alt="peppermint logo" src="https://mintea.pw/img/peppermint.svg"></img>
    <h3>peppermint</h3>
    straightforward Filament-based PBR shader targeting Unity's BIRP and URP pipelines, intended for VRChat/BasisVR avatar usage.
</div>

---

### "features"
* [Filament](https://google.github.io/filament/Filament.md.html) based
* uses ORM (Occlusion, Roughness, Metallic)
* *birp:* [Light Volumes](https://github.com/REDSIM/VRCLightVolumes/tree/main) support 
* *birp:* [LTCGI](https://ltcgi.dev/) support
* *urp:* [APV](https://docs.unity3d.com/6000.0/Documentation/Manual/urp/probevolumes.html) support

### notes
features are sparse, this is meant to be a personal usage shader first and foremost; feel free to open issues/prs with reasonable intent.

this shader is meant for "client" usage, a.k.a. dynamic player objects/avatars; it does sample from light probes and additional dynamic-lighting systems (refer "features"), but it does not sample baked world lightmaps and should not be used for world projects.