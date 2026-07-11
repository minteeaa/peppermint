<div align=center class=flex>
    <img height="125" alt="peppermint logo" src="https://mintea.pw/img/peppermint.svg"></img>
    <h3>peppermint</h3>
    <p>straightforward Filament-based PBR shader targeting Unity's BIRP and URP pipelines, intended for VRChat/BasisVR avatar usage.</p>
</div>

---

### "features"
* [Filament](https://google.github.io/filament/Filament.md.html) based
* ORM workflow
* *birp:* [Light Volumes](https://github.com/REDSIM/VRCLightVolumes/tree/main) support 
* *birp:* [LTCGI](https://ltcgi.dev/) support
* *urp:* [APV](https://docs.unity3d.com/6000.0/Documentation/Manual/urp/probevolumes.html) support

### ORM?
ORM maps (also referred to as ARM maps) are a common format for packed textures to be used on game-ready assets and materials

these maps are packed to an image (like any other map) with RGB channels referring to:
* R: Ambient Occlusion
* G: Roughness
* B: Metallic

peppermint doesn't have a built-in UI for packing your own ORM maps, there are many available texture packers/baking tools for Unity (and Blender) on the internet to use, such as:
* *blender:* [SimpleBake](https://superhivemarket.com/products/simplebake---simple-pbr-and-other-baking-in-blender-2)
* *unity:* [unity-texture-packer by zynres](https://github.com/zynres/unity-texture-packer)
* *unity:* [Pumkin's Avatar Tools](https://github.com/rurre/PumkinsAvatarTools)

### notes
features are sparse, this is meant to be a personal usage shader first and foremost; feel free to open issues/prs with reasonable intent.

this shader is meant for "client" usage, a.k.a. dynamic player objects/avatars; it does sample from light probes and additional dynamic-lighting systems (refer "features"), but it does not sample baked world lightmaps and should not be used for world projects.