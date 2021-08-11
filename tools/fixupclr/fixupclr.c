/* fixupclr - Modifies headers of .exe files to set architecture
 * Usage: fixupclr.exe arch filename [filename [...]] */

#include <wchar.h>
#include <stdio.h>

#include <windows.h>

static BOOL set_version = TRUE;
static BOOL set_32only = FALSE;

BOOL read_file(HANDLE hfile, void *buffer, DWORD len)
{
	DWORD bytesread;
	BOOL result;

	while (len)
	{
		result = ReadFile(hfile, buffer, len, &bytesread, NULL);
		if (!result || bytesread == 0)
			return FALSE;
		len -= bytesread;
		buffer = (char*)buffer + bytesread;
	}

	return TRUE;
}

BOOL write_file(HANDLE hfile, const void *buffer, DWORD len)
{
	DWORD byteswritten;
	BOOL result;

	while (len)
	{
		result = WriteFile(hfile, buffer, len, &byteswritten, NULL);
		if (!result || byteswritten == 0)
			return FALSE;
		len -= byteswritten;
		buffer = (const char*)buffer + byteswritten;
	}

	return TRUE;
}

DWORD rva_to_offset(const IMAGE_SECTION_HEADER *sections, int num_sections, DWORD rva)
{
	int i;
	for (i=0; i<num_sections; i++)
	{
		if (sections[i].VirtualAddress <= rva &&
			sections[i].VirtualAddress + sections[i].SizeOfRawData > rva)
		{
			return sections[i].PointerToRawData + rva - sections[i].VirtualAddress;
		}
	}

	return 0;
}

int set_32only_flag(const wchar_t* path)
{
	HANDLE hfile;
	IMAGE_DOS_HEADER dosheader;
	IMAGE_NT_HEADERS32 ntheaders;
	IMAGE_SECTION_HEADER sections[96];
	int num_sections;
	DWORD clr_header_ofs;
	IMAGE_COR20_HEADER clr_header;

	hfile = CreateFile(path, GENERIC_READ|GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL, NULL);
	if (!hfile || hfile == INVALID_HANDLE_VALUE)
	{
		fwprintf(stderr, L"%ls: Cannot open, error %d\n", path, GetLastError());
		return 1;
	}

	if (!read_file(hfile, &dosheader, sizeof(dosheader)))
	{
		fwprintf(stderr, L"%ls: Cannot read DOS header, error %d\n", path, GetLastError());
		CloseHandle(hfile);
		return 1;
	}

	if (dosheader.e_magic != IMAGE_DOS_SIGNATURE)
	{
		fwprintf(stderr, L"%ls: Not an exe file\n", path);
		CloseHandle(hfile);
		return 1;
	}

	SetFilePointer(hfile, dosheader.e_lfanew, NULL, FILE_BEGIN);

	if (!read_file(hfile, &ntheaders, sizeof(ntheaders)))
	{
		fwprintf(stderr, L"%ls: Cannot read NT headers, error %d\n", path, GetLastError());
		CloseHandle(hfile);
		return 1;
	}

	if (memcmp(&ntheaders.Signature, "PE\0\0", 4) != 0)
	{
		fwprintf(stderr, L"%ls: Not a PE file\n", path);
		CloseHandle(hfile);
		return 1;
	}

	if (ntheaders.FileHeader.SizeOfOptionalHeader != IMAGE_SIZEOF_NT_OPTIONAL32_HEADER)
	{
		fwprintf(stderr, L"%ls: Not a 32-bit image\n", path);
		CloseHandle(hfile);
		return 1;
	}

	num_sections = min(ntheaders.FileHeader.NumberOfSections, 96);

	if (!read_file(hfile, sections, sizeof(sections[0])*num_sections))
	{
		fwprintf(stderr, L"%ls: Cannot read NT section table, error %d\n", path, GetLastError());
		CloseHandle(hfile);
		return 1;
	}

	clr_header_ofs = rva_to_offset(sections, num_sections,
		ntheaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR].VirtualAddress);
	if (!clr_header_ofs)
	{
		fwprintf(stderr, L"%ls: Not a CLR image\n", path);
		CloseHandle(hfile);
		return 1;
	}

	SetFilePointer(hfile, clr_header_ofs, NULL, FILE_BEGIN);

	if (!read_file(hfile, &clr_header, sizeof(clr_header)))
	{
		fwprintf(stderr, L"%ls: Cannot read CLR header, error %d\n", path, GetLastError());
		CloseHandle(hfile);
		return 1;
	}

	if (set_32only)
		clr_header.Flags |= COMIMAGE_FLAGS_32BITREQUIRED;
	
	if (set_version)
	{
		clr_header.MajorRuntimeVersion = 2;
		clr_header.MinorRuntimeVersion = 5;
	}

	SetFilePointer(hfile, clr_header_ofs, NULL, FILE_BEGIN);

	if (!write_file(hfile, &clr_header, sizeof(clr_header)))
	{
		fwprintf(stderr, L"%ls: Cannot write CLR header, error %d\n", path, GetLastError());
		CloseHandle(hfile);
		return 1;
	}

	CloseHandle(hfile);
	return 0;
}

int wmain(int argc, wchar_t **argv)
{
	int result=0;
	int i;

	if (wcscmp(argv[1], L"x86") == 0)
	{
		set_32only = TRUE;
		set_version = TRUE;
	}
	else if (wcscmp(argv[1], L"x86_64") == 0)
	{
		set_version = TRUE;
	}
	else
	{
		fwprintf(stderr, L"Unknown architecture\n");
		return 1;
	}

	for (i=2; i<argc; i++)
	{
		result |= set_32only_flag(argv[i]);
	}

	return result;
}
