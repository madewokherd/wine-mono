#include <windows.h>

extern INT __cdecl test_mixed_export(INT input);

int main(int argc, char* argv[])
{
	return test_mixed_export(-5);
}
