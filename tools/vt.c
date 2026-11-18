#include <windows.h>
#include <wintrust.h>
#include <softpub.h>
#include <stdio.h>
int wmain(int argc, wchar_t **argv)
{
    for (int i = 1; i < argc; i++) {
        WINTRUST_FILE_INFO fi = { sizeof(fi), argv[i] };
        WINTRUST_DATA wd = { sizeof(wd) };
        GUID action = WINTRUST_ACTION_GENERIC_VERIFY_V2;
        wd.dwUIChoice = WTD_UI_NONE; wd.dwUnionChoice = WTD_CHOICE_FILE; wd.pFile = &fi; wd.dwStateAction = WTD_STATEACTION_VERIFY;
        LONG r = WinVerifyTrust(NULL, &action, &wd);
        wprintf(L"%08lx %ls\n", (unsigned long)r, argv[i]);
        wd.dwStateAction = WTD_STATEACTION_CLOSE; WinVerifyTrust(NULL, &action, &wd);
    }
    return 0;
}
