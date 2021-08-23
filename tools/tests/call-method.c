#include <windows.h>
#include <stdio.h>
#include <initguid.h>
#define COBJMACROS
#include <mscoree.h>
#include "metahost.h"

#define CHECK(expr) do { hr = (expr); if (hr) { printf("Expression '%s' on line %i returned 0x%lx\n", #expr, __LINE__, hr); return hr; } } while (0)

HRESULT (WINAPI *pCLRCreateInstance)(REFCLSID clsid, REFIID riid, LPVOID *ppInterface);

int wmain(int argc, wchar_t* argv[])
{
	HMODULE hmscoree;
	ICLRMetaHost *metahost;
	ICLRRuntimeInfo *info;
	ICLRRuntimeHost *host;
	DWORD result;
	HRESULT hr;

	if (argc < 5)
	{
		printf("Usage: call-method assembly.dll typename methodname argument\n");
		return 1;
	}

	hmscoree = LoadLibraryW(L"mscoree");
	pCLRCreateInstance = (void*)GetProcAddress(hmscoree, "CLRCreateInstance");

	CHECK(pCLRCreateInstance(&CLSID_CLRMetaHost, &IID_ICLRMetaHost, (void**)&metahost));

	CHECK(ICLRMetaHost_GetRuntime(metahost, L"v4.0.30319", &IID_ICLRRuntimeInfo, (void**)&info));

	CHECK(ICLRRuntimeInfo_GetInterface(info, &CLSID_CLRRuntimeHost, &IID_ICLRRuntimeHost, (void**)&host));

	ICLRRuntimeHost_Start(host);

	CHECK(ICLRRuntimeHost_ExecuteInDefaultAppDomain(host, argv[1], argv[2], argv[3], argv[4], &result));

	ICLRRuntimeHost_Release(host);
	ICLRRuntimeInfo_Release(info);
	ICLRMetaHost_Release(metahost);

	return result;
}
