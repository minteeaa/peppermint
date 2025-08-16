#define INIT_TEX2D(tex)														    Texture2D tex; SamplerState sampler##tex
#define INIT_TEX2D_NOSAMPLER(tex)												Texture2D tex

#define TEX2D_SAMPLE(tex,coord)				                                    tex.Sample(sampler##tex,coord)
#define TEX2D_SAMPLE_SAMPLER(tex,texSampler,coord)								tex.Sample(texSampler,coord)