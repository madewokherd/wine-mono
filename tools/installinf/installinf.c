/* installinf - Use setupapi to install a .inf file.
 *
 * We cannot use rundll32 for this because Wine Mono may be installed before it is created. */

#include <stdlib.h>
#include <wchar.h>
#include <windows.h>
#include <setupapi.h>

int wmain(int argc, wchar_t **argv)
{
	wchar_t* buf;
	const wchar_t* prefix = L"DefaultInstall 128 ";

	buf = malloc(sizeof(wchar_t) * (wcslen(prefix) + wcslen(argv[1]) + 1));

	wcscpy(buf, prefix);
	wcscat(buf, argv[1]);

	InstallHinfSectionW(NULL, NULL, buf, 0);

	return 0;
}
