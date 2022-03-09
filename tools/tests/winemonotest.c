
#define COBJMACROS

#include <windows.h>
#include <oaidl.h>

#include <stdio.h>

#define COR_E_SAFEARRAYTYPEMISMATCH 0x80131533
#define COR_E_SAFEARRAYRANKMISMATCH 0x80131538

#include <initguid.h>

DEFINE_GUID(IID_ICCWTest, 0x209706eb, 0x0a9c, 0x4651, 0xbc, 0xb8, 0x58, 0x2f, 0x19, 0xfb, 0xfb, 0xd8);

typedef struct ICCWTest ICCWTest;

typedef struct
{
	HRESULT (WINAPI *QueryInterface)(ICCWTest *iface, REFIID riid, void **punk);
	int (WINAPI *AddRef)(ICCWTest *iface);
	int (WINAPI *Release)(ICCWTest *iface);
	int (WINAPI *in_safearrayvariant_array)(ICCWTest *iface, SAFEARRAY *sa);
	int (WINAPI *in_safearrayi4_array)(ICCWTest *iface, SAFEARRAY *sa);
} ICCWTestVtbl;

struct ICCWTest
{
	ICCWTestVtbl *lpVtbl;
};

#define CHECK(expr) do { hr = (expr); if (hr) { printf("Expression '%s' on line %i returned 0x%lx", #expr, __LINE__, hr); return hr; } } while (0)
#define ASSERT(expr) do { hr = (expr); if (!hr) { printf("Check '%s' failed on line %i", #expr, __LINE__); return 1; } } while (0)

int CDECL do_ccw_tests(IUnknown *unk)
{
	HRESULT hr;
	ICCWTest *ccwtest;
	SAFEARRAYBOUND sab[2] = { { 0 } };
	LONG sai[] = { 0 };
	SAFEARRAY *sa;
	VARIANT var;
	LONG lVal;

	CHECK(IUnknown_QueryInterface(unk, &IID_ICCWTest, (void**)&ccwtest));

	sab[0].cElements = 3;
	sab[0].lLbound = 0;
	sa = SafeArrayCreate(VT_VARIANT, 1, sab);

	VariantInit(&var);
	V_VT(&var) = VT_I4;
	V_I4(&var) = 2;
	sai[0] = 0;
	CHECK(SafeArrayPutElement(sa, sai, &var));

	CHECK(ccwtest->lpVtbl->in_safearrayvariant_array(ccwtest, sa));
	ASSERT(ccwtest->lpVtbl->in_safearrayi4_array(ccwtest, sa) == COR_E_SAFEARRAYTYPEMISMATCH);

	CHECK(SafeArrayDestroy(sa));

	sab[0].cElements = 3;
	sab[0].lLbound = 0;
	sa = SafeArrayCreate(VT_I4, 1, sab);

	lVal = 2;
	CHECK(SafeArrayPutElement(sa, sai, &lVal));

	ASSERT(ccwtest->lpVtbl->in_safearrayvariant_array(ccwtest, sa) == COR_E_SAFEARRAYTYPEMISMATCH);
	CHECK(ccwtest->lpVtbl->in_safearrayi4_array(ccwtest, sa));

	CHECK(SafeArrayDestroy(sa));

	sab[0].cElements = 3;
	sab[0].lLbound = 0;
	sab[1].cElements = 3;
	sab[1].lLbound = 0;
	sa = SafeArrayCreate(VT_I4, 2, sab);

	ASSERT(ccwtest->lpVtbl->in_safearrayvariant_array(ccwtest, sa) == COR_E_SAFEARRAYRANKMISMATCH);
	ASSERT(ccwtest->lpVtbl->in_safearrayi4_array(ccwtest, sa) == COR_E_SAFEARRAYRANKMISMATCH);

	CHECK(SafeArrayDestroy(sa));

	ccwtest->lpVtbl->Release(ccwtest);

	return 0;
}

void* CDECL get_valist_argument(INT index, va_list va)
{
	while (index-- > 0)
	{
		va_arg(va, void*);
	}

	return va_arg(va, void*);
}

#ifdef __i386__
/* For some reason, on x86 IsCopyConstructed marshaling behaves differently. */
int __stdcall dereference_int(int val)
{
	return val;
}

int __stdcall call_copy_constructed(void* fn, int val)
{
	int (__stdcall *fn_typed)(int val) = fn;
	return fn_typed(val);
}
#else
int __stdcall dereference_int(int* ptr)
{
	int result = *ptr;
	*ptr = 25;
	return result;
}

int __stdcall call_copy_constructed(void* fn, int val)
{
	int (__stdcall *fn_typed)(int* val) = fn;
	return fn_typed(&val);
}
#endif

