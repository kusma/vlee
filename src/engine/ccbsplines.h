#pragma once

#include "effect.h"
#include "particlestreamer.h"
#include "../math/vector3.h"
#include "../renderer/device.h"
using math::Vector3;

namespace engine
{
	class CCBSplines {
	public:
		#define CSNK 40		//num of knots per spline loop
		#define CSLOD 128	//level of detail per knot
		#define	CSLOOP 20	//num of spline loops

		struct CCBSplineLoop {
			Vector3 knots[CSNK];
			Vector3 vectors[CSNK*CSLOD];
		};

		CCBSplines(renderer::Device &device) : device(device) {
			ps = ParticleStreamer(device);
			generateSplineLoops();
		}

		void draw(engine::Effect &effect, double time);
	private:
		void drawFrame(engine::Effect &effect, double time);

		void generateSplineLoops();
		void generateKnots(int mod, CCBSplineLoop& sl);
		void generateSplines(CCBSplineLoop& sl);

		renderer::Device &device;
		ParticleStreamer ps;
		CCBSplineLoop loops[CSLOOP];

	};
}
