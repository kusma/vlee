#pragma once

#include "../core/fatalexception.h"
#include "../core/log.h"
#include "../core/comref.h"
#include "../core/err.h"
#include "device.h"

namespace renderer
{
	class VertexBuffer : public ComRef<IDirect3DVertexBuffer9>
	{
	public:
		VertexBuffer(IDirect3DVertexBuffer9 *vertex_buffer = NULL) : ComRef<IDirect3DVertexBuffer9>(vertex_buffer) {}

		void *lock(UINT offset, UINT size, DWORD flags)
		{
			assert(NULL != p);
			void *mem = 0;
			core::d3dErr(p->Lock(offset, size, &mem, flags));
			assert(NULL != mem);
			return mem;
		}

		void unlock()
		{
			p->Unlock();
		}
	};
}
