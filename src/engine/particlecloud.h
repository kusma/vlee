#include "../math/vector3.h"
#include <vector>
#include <algorithm>

namespace engine
{
	template <typename T>
	class Particle
	{
	public:
		Particle() {}
		Particle(const math::Vector3 &pos, const T &data) : pos(pos), data(data) {}

		math::Vector3 pos;
		T data;
	};

	template <typename T>
	class ParticleComparer : public std::binary_function<const Particle<T> &, const Particle<T> &, bool>
	{
	public:
		ParticleComparer(const math::Vector3 &view_vector) : view_vector(view_vector) {}
		
		bool operator()(const Particle<T> &p1, const Particle<T> &p2) const
		{
			float dot1 = math::dot(view_vector, p1.pos);
			float dot2 = math::dot(view_vector, p2.pos);
			if (fabs(dot1 - dot2) > 1e-10) return dot1 > dot2;
			return false;
		}
		
		const math::Vector3 view_vector;
	};

	template <typename T>
	class ParticleCloud
	{
	public:
		void sort(const math::Vector3 &view_vector)
		{
//			particles.sort(ParticleComparer<T>(view_vector));
			std::stable_sort(particles.begin(), particles.end(), ParticleComparer<T>(view_vector));
		}

		void addParticle(const Particle<T> &p)
		{
			particles.push_back(p);
		}

		typedef std::vector<Particle<T> > ParticleContainer;
		ParticleContainer particles;
	};
}
