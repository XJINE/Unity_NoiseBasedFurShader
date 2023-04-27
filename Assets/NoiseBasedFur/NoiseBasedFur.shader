Shader "Unlit/NoiseBasedFur"
{
    Properties
    {
        _MainTex     ("Texture",          2D   ) = "white" {}
        _Iteration   ("Iteration",        Int  ) = 5
        _Length      ("Length",           Float) = 3
        _SwayAngle   ("Sway Angle (Deg)", Float) = 15
        _SwaySpeed   ("Sway Speed",       Float) = 15
        _Turbulence  ("Turbulence",       Float) = 0.01
        _CurlDensity ("Curl Density",     Float) = 5
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }

        Pass
        {
            CGPROGRAM

            #pragma vertex   vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv     : TEXCOORD0;
            };

            sampler2D _MainTex;
            float2    _MainTex_TexelSize;

            int   _Iteration;
            float _Length;
            float _SwayAngle;
            float _SwaySpeed;
            float _Turbulence;
            float _CurlDensity;

            float random(float2 seeds)
            {
                return frac(sin(dot(seeds, float2(12.9898, 78.233))) * 43758.5453);
            }

            float perlinNoise(float2 seeds) 
            {
                float2 p = floor(seeds);
                float2 f = frac (seeds);
                float2 u = f * f * (3.0 - 2.0 * f);

                float v00 = random(p + float2(0,0));
                float v10 = random(p + float2(1,0));
                float v01 = random(p + float2(0,1));
                float v11 = random(p + float2(1,1));

                return lerp(lerp(dot(v00, f - float2(0,0)), dot(v10, f - float2(1,0)), u.x),
                            lerp(dot(v01, f - float2(0,1)), dot(v11, f - float2(1,1)), u.x), 
                            u.y) + 0.5;
            }

            v2f vert (appdata_full v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv     = v.texcoord;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                const float DEG_TO_RAD = 0.0174533;

                float turbulence = perlinNoise(i.uv * _Turbulence);
                float curl       = perlinNoise(i.uv * _CurlDensity);
                      curl       = lerp(-1, 1, curl);

                // NOTE:
                // cos(_Time) makes animation more complex.

                float    angle     = cos(_Time.y) * sin(_Time.x * _SwaySpeed * turbulence) * _SwayAngle * DEG_TO_RAD;
                float2x2 rotate    = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
                float2   direction = normalize(mul(rotate, float2(0, 1) + curl));

                float4 color = half4(0, 0, 0, 0);
                float2 uv    = i.uv;

                for (int i = 0; i < _Iteration; i++)
                {
                    color += tex2D(_MainTex, uv);
                    uv    += direction * _MainTex_TexelSize * _Length;
                }

                return color / _Iteration;
            }

            ENDCG
        }
    }
}