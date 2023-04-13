# Unity的粒子贴花

## 简介

这个Demo介绍了粒子贴花，通过粒子发射器ParticleSystem发射贴花，有两个Demo

> 一个是ParticleDecal，展示了粒子静态贴花

![GitHub](https://github.com/xieliujian/UnityDemo_ParticleDecal/blob/main/Video/ParticleDecal.png?raw=true)

> 一个是ParticleDecalCombine，是复合贴花，可以通过ParticleSystem设置旋转，缩放，位移和溶解等效果

![GitHub](https://github.com/xieliujian/UnityDemo_ParticleDecal/blob/main/Video/ParticleDecalCombine.png?raw=true)

## 功能介绍

### Shader部分

```C#

// 主要是贴花uv坐标的获取，关于其他的符合效果可以参考代码

// vs

o.screenUV = ComputeScreenPos (o.pos);
o.ray = TransformWorldToView(TransformObjectToWorld(v.vertex.xyz).xyz ) * float3(-1,-1,1);

// ps

i.ray = i.ray * (_ProjectionParams.z / i.ray.z);

float2 uv = i.screenUV.xy / i.screenUV.w;
float depth = SampleSceneDepth(uv);

// 要转换成线性的深度值 Linear01Depth在 common.hlsl里面
depth = Linear01Depth (depth, _ZBufferParams);

float4 vpos = float4(i.ray * depth, 1);
float3 wpos = mul (unity_CameraToWorld, vpos).xyz;

float3 opos = mul(_World2ObjMatrix, float4(wpos, 1.0)).xyz;

// 只留下一个面
clip (float3(0.5,0.5,0.5) - abs(opos));

// 贴花坐标 转换到 [0,1] 区间
float2 texUV = opos.xz + 0.5;

```

### 代码部分

```C#

// 这个函数是计算Shader中粒子的位置，修正位置达到正确的效果

void UpdateWorldMatrix()
{
    if (m_material == null)
        return;

    var particle = m_particleArray[0];
    // 注意，粒子取出的位置是世界空间位置
    var pos = transform.position;
    var rot = transform.rotation * Quaternion.Euler(particle.rotation3D);

    // 模型只能用默认的Cube，默认的Cube模型尺寸是1
    var scale = particle.GetCurrentSize3D(m_particleSystem);
    scale = Vector3.Scale(scale, transform.localScale);

    m_worldInvMat.SetTRS(pos, rot, scale);
    m_worldInvMat = m_worldInvMat.inverse;

    // 计算得到最终的世界转换矩阵
    m_material.SetMatrix("_World2ObjMatrix", m_worldInvMat);
}

```

## 源项目链接

[ColinLeung-NiloCat](https://github.com/ColinLeung-NiloCat/UnityURPUnlitScreenSpaceDecalShader)