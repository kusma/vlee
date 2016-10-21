#pragma once

#include "vector3.h"
#include "quaternion.h"

namespace math
{
	class Matrix4x4 : public D3DXMATRIX
	{
	public:
		Matrix4x4() {}
		Matrix4x4(const Matrix4x4 &mat) : D3DXMATRIX(mat) { }
		Matrix4x4(const D3DXMATRIX &mat) : D3DXMATRIX(mat) { }
		
		static Matrix4x4 identity()
		{
			Matrix4x4 ret;
			ret.makeIdentity();
			return ret;
		}
		
		static Matrix4x4 translation(const Vector3 &translate)
		{
			Matrix4x4 ret;
			ret.makeTranslation(translate);
			return ret;
		}
		
		static Matrix4x4 rotation(const Vector3 &rotate)
		{
			Matrix4x4 ret;
			ret.makeRotation(rotate);
			return ret;
		}
		
		static Matrix4x4 rotation(const Quaternion &rotate)
		{
			Matrix4x4 ret;
			D3DXMatrixRotationQuaternion(&ret, &rotate);
			return ret;
		}
		
		static Matrix4x4 scaling(const Vector3 &scale)
		{
			Matrix4x4 ret;
			ret.makeScaling(scale);
			return ret;
		}
		
		static Matrix4x4 projection(float fov, float aspect, float znear, float zfar)
		{
			Matrix4x4 ret;
			ret.makeProjection(fov, aspect, znear, zfar);
			return ret;
		}

		static Matrix4x4 lookAt(const Vector3 &eye, const Vector3 &target, float roll)
		{
			Matrix4x4 ret;
			ret.makeLookAt(eye, target, roll);
			return ret;
		}
		
		void makeIdentity()
		{
			D3DXMatrixIdentity(this);
		}
		
		void makeTranslation(const Vector3 &translate)
		{
			D3DXMatrixTranslation(this, translate.x, translate.y, translate.z);
		}
		
		void makeRotation(const Vector3 &rotation)
		{
			D3DXMatrixRotationYawPitchRoll(this, rotation.y, rotation.x, rotation.z);
		}
		
		void makeScaling(const Vector3 &scale)
		{
			D3DXMatrixScaling(this, scale.x, scale.y, scale.z);
		}
		
		void makeProjection(float fov, float aspect, float znear, float zfar)
		{
			D3DXMatrixPerspectiveFovLH(this, D3DXToRadian(fov), aspect, znear, zfar);
		}
		
		void makeLookAt(const Vector3 &eye, const Vector3 &target, float roll)
		{
			D3DXVECTOR3 up(0, 1, 0);
			D3DXMatrixLookAtLH(this, &eye, &target, &up);
			*this *= rotation(Vector3(0, 0, roll));;
		}

		void extractFrustumPlanes(float frustum[6][4])
		{
			// Left clipping plane
			frustum[0][0] = _14 + _11;
			frustum[0][1] = _24 + _21;
			frustum[0][2] = _34 + _31;
			frustum[0][3] = _44 + _41;

			// Right clipping plane
			frustum[1][0] = _14 - _11;
			frustum[1][1] = _24 - _21;
			frustum[1][2] = _34 - _31;
			frustum[1][3] = _44 - _41;

			// Top clipping plane
			frustum[2][0] = _14 - _12;
			frustum[2][1] = _24 - _22;
			frustum[2][2] = _34 - _32;
			frustum[2][3] = _44 - _42;

			// Bottom clipping plane
			frustum[3][0] = _14 + _12;
			frustum[3][1] = _24 + _22;
			frustum[3][2] = _34 + _32;
			frustum[3][3] = _44 + _42;

			// Near clipping plane
			frustum[4][0] = _13;
			frustum[4][1] = _23;
			frustum[4][2] = _33;
			frustum[4][3] = _43;

			// Far clipping plane
			frustum[5][0] = _14 - _13;
			frustum[5][1] = _24 - _23;
			frustum[5][2] = _34 - _33;
			frustum[5][3] = _44 - _43;
		}

		Matrix4x4 inverse() const
		{
			Matrix4x4 res;
			D3DXMatrixInverse(&res, NULL, this);
			return res;
		}

		Matrix4x4 transpose() const
		{
			Matrix4x4 res;
			D3DXMatrixTranspose(&res, this);
			return res;
		}

		Vector3 getTranslation() const
		{
			return Vector3(_41, _42, _43);
		}
		
		Vector3 getZAxis() const
		{
			return Vector3(_13, _23, _33);
		}
	};

	inline Vector3 mul(const Matrix4x4 &m, const Vector3 &v)
	{
		Vector3 ret;
		D3DXVec3TransformCoord(
			&ret,
			&v,
			&m
		);
		return ret;
	}

}
