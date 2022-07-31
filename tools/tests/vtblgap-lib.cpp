// dllmain.cpp : Defines the entry point for the DLL application.
#include <windows.h>
#include <unknwn.h>

class ITest1 : public IUnknown
{
    virtual int WINAPI itest1_method1(int *ret) = 0;
};

class ITest2 : public ITest1
{
    virtual int WINAPI method1(int *ret) = 0;
    virtual int WINAPI method2(int* ret) = 0;
    virtual int WINAPI method3(int* ret) = 0;
};


class Test : public ITest2
{
    HRESULT WINAPI QueryInterface(const IID& iid, void** out)
    {
        GUID guid1, guid2;

        IIDFromString(L"{deadbeef-0000-0000-c000-000000000001}", &guid1);
        IIDFromString(L"{deadbeef-0000-0000-c000-000000000002}", &guid2);

        if (IsEqualIID(IID_IUnknown, iid)
            || IsEqualIID(guid1, iid) || IsEqualIID(guid2, iid))
        {
            *out = static_cast<ITest2*>(this);
            return S_OK;
        }
        return E_NOINTERFACE;
    }
    ULONG WINAPI AddRef()
    {
        return 1;
    }
    ULONG WINAPI Release()
    {
        return 1;
    }
    int WINAPI itest1_method1(int *ret)
    {
        *ret = 1;
        return 0;
    }

    int WINAPI method1(int *ret)
    {
        *ret = 11;
        return 0;
    }
    int WINAPI method2(int* ret)
    {
        *ret = 12;
        return 0;
    }
    int WINAPI method3(int* ret)
    {
        *ret = 13;
        return 0;
    }
};

class Test test;

extern "C"
{
    __declspec(dllexport) IUnknown* get_object()
    {
        return &test;
    }
};

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

