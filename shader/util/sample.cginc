#define INIT_TEX2D(tex)														    Texture2D tex; SamplerState sampler##tex
#define TEX2D_SAMPLE(tex,coord)				                                    tex.Sample(sampler##tex,coord)

#if defined(PIPE_BIRP)
    #define INIT_TEX2D_NOSAMPLER(tex)											Texture2D tex; SamplerState sampler##tex
    #define TEX2D_SAMPLE_SAMPLER(tex,texSampler,coord)							tex.Sample(texSampler,coord)
    #define INIT_TEX2D_BCSAMPLER(tex)                                           Texture2D tex; SamplerState sampler##tex##_bilinear_clamp
    #define INIT_TEX2D_PWSAMPLER(tex)                                           Texture2D tex; SamplerState sampler##tex
#elif defined(PIPE_URP)
    #define INIT_TEX2D_NOSAMPLER(tex)											Texture2D tex; SAMPLER(sampler##tex)
    #define TEX2D_SAMPLE_SAMPLER(tex,texSampler,coord)							SAMPLE_TEXTURE2D(tex,sampler##tex,coord)
    #define INIT_TEX2D_BCSAMPLER(tex)                                           Texture2D tex; SamplerState sampler##tex{ Filter = MIN_MAG_MIP_LINEAR; AddressU = Clamp; AddressV = Clamp; }
    #define INIT_TEX2D_PWSAMPLER(tex)                                           Texture2D tex; SamplerState sampler##tex{ Filter = MIN_MAG_MIP_POINT; AddressU = Wrap; AddressV = Wrap; }
#endif