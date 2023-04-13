using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace gtmGame
{
    [ExecuteInEditMode]
    public class ParticleDecal : MonoBehaviour
    {
        private ParticleSystem m_particleSystem;

        private Material m_material;

        private ParticleSystem.Particle[] m_particleArray = new ParticleSystem.Particle[1];

        private Matrix4x4 m_worldInvMat = new Matrix4x4();

        // Start is called before the first frame update
        void Start()
        {
            m_particleSystem = GetComponent<ParticleSystem>();

            var render = GetComponent<Renderer>();
            if (render != null)
            {
                m_material = render.sharedMaterial;
            }
        }

        // Update is called once per frame
        void Update()
        {
            CacheFirstParticle();
            UpdateWorldMatrix();
        }

        private void UpdateWorldMatrix()
        {
            if (m_material == null)
                return;

            var particle = m_particleArray[0];
            var pos = transform.position;
            var rot = transform.rotation * Quaternion.Euler(particle.rotation3D);

            // 模型只能用默认的Cube，默认的Cube模型尺寸是1
            var scale = particle.GetCurrentSize3D(m_particleSystem);
            scale = Vector3.Scale(scale, transform.localScale);

            m_worldInvMat.SetTRS(pos, rot, scale);
            m_worldInvMat = m_worldInvMat.inverse;

            m_material.SetMatrix("_World2ObjMatrix", m_worldInvMat);
        }

        private void CacheFirstParticle()
        {
            m_particleSystem.GetParticles(m_particleArray, 1);
        }
    }
}
