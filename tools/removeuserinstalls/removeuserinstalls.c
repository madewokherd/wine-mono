/* removeuserinsalls - Remove single-user installs of Wine Mono msi's.
 *
 * These can't be upgraded cleanly to a system install. */

#include <stdlib.h>
#include <wchar.h>
#include <windows.h>
#include <msi.h>

void remove_user_install(const WCHAR* upgrade_code)
{
    WCHAR productcode[39];
	MSIHANDLE hproduct;
	WCHAR allusers[5];
	DWORD allusers_len = 5;
	DWORD err;

	if (MsiEnumRelatedProductsW(upgrade_code, 0, 0, productcode) != ERROR_SUCCESS)
		return;

	if (MsiOpenProductW(productcode, &hproduct) != ERROR_SUCCESS)
		return;

	if (MsiGetProductPropertyW(hproduct, L"ALLUSERS", allusers, &allusers_len) == ERROR_SUCCESS)
	{
		if (allusers[0])
		{
			/* System install, nothing to do. */
			MsiCloseHandle(hproduct);
			return;
		}
	}

	MsiCloseHandle(hproduct);

	MsiConfigureProductExW(productcode, INSTALLLEVEL_DEFAULT, INSTALLSTATE_DEFAULT, L"REMOVE=ALL");
}

int wmain(int argc, wchar_t **argv)
{
	static const WCHAR* runtime_upgrade_code = L"{DF105CC2-8FA2-4367-B1D3-95C63C0941FC}";
	static const WCHAR* support_upgrade_code = L"{DE624609-C6B5-486A-9274-EF0B854F6BC5}";

	CoInitialize(NULL);

	remove_user_install(runtime_upgrade_code);
	remove_user_install(support_upgrade_code);

	CoUninitialize();

	return 0;
}
