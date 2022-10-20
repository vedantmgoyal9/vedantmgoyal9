# On Windows 10? Change the image to mcr.microsoft.com/windows:20H2
FROM mcr.microsoft.com/windows/server:ltsc2022 as get-arp-winget
USER ContainerAdministrator
WORKDIR C:\\working-dir
COPY functions.ps1 vc_redist.x64.exe wingetdev ./
SHELL [ "powershell", "-Command" ]
# block microsoft edge updates 
RUN New-Item -Path HKLM:\\SOFTWARE\\Microsoft\\EdgeUpdate -Force
RUN New-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\EdgeUpdate -Name DoNotUpdateToEdgeWithChromium -Value 1 -PropertyType DWord -Force
RUN Remove-Item -Force -Recurse 'C:\\Program Files (x86)\\Microsoft\\EdgeUpdate\\'
RUN Set-Service -Name edgeupdate -Status Stopped -StartupType Disabled # stop edgeupdate service
RUN Set-Service -Name edgeupdatem -Status Stopped -StartupType Disabled # stop edgeupdatem service
# install vc_redist.x64.exe required for wingetdev, enable installation of local manifests by wingetdev
RUN .\vc_redist.x64.exe /install /passive /quiet /norestart /log ./vc_redist.log
RUN .\wingetdev.exe settings --enable LocalManifestFiles
ENTRYPOINT [ "powershell" ]
CMD [ ". .\\functions.ps1; Initialize-Container;" ]
