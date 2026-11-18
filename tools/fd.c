#define COBJMACROS
#include <windows.h>
#include <shobjidl.h>
#include <stdio.h>
int wmain(int argc, WCHAR **argv)
{
    IFileDialog *fd; IShellItem *it; WCHAR *path; HRESULT hr; DWORD opts;
    int save = argc > 1 && !wcscmp(argv[1], L"save");
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    hr = CoCreateInstance(save ? &CLSID_FileSaveDialog : &CLSID_FileOpenDialog, NULL, CLSCTX_INPROC_SERVER, &IID_IFileDialog, (void **)&fd);
    if (FAILED(hr)) { printf("create %08lx\n", hr); return 1; }
    if (!save) { IFileDialog_GetOptions(fd, &opts); IFileDialog_SetOptions(fd, opts | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM); }
    else IFileDialog_SetFileName(fd, L"Project_1.flp");
    IFileDialog_SetTitle(fd, save ? L"Save as (portal test)" : L"Select Folder (portal test)");
    hr = IFileDialog_Show(fd, NULL);
    printf("show %08lx\n", hr);
    if (SUCCEEDED(hr) && SUCCEEDED(IFileDialog_GetResult(fd, &it)) && SUCCEEDED(IShellItem_GetDisplayName(it, SIGDN_FILESYSPATH, &path)))
        printf("result %ls\n", path);
    fflush(stdout);
    return 0;
}
