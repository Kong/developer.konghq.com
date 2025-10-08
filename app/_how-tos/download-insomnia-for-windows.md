---
title: Download Insomnia on Windows with NSIS installer

content_type: how_to

products:
- insomnia

description: Learn how to install Insomnia on a Windows device with the NSIS installer.

tags:
  - insomnia
  - install
  - windows

breadcrumbs:
  - /insomnia/

min_version:
  insomnia: '11.3.0'

prereqs:
  skip_product: true
  inline:
    - title: "Windows"
      content: |
        To install and run Insomnia on Windows, you need Windows 10 or later.
      icon_url: /assets/icons/third-party/windows.svg

tldr:
  q: How do I download Insomnia on a Windows device?
  a: Go to the [latest Insomnia release](https://github.com/Kong/insomnia/releases/tag/core%40{{ site.data.insomnia_latest.version }}) on GitHub and download the `Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe` file.
faqs:
  - q: How do I uninstall Insomnia from my Windows device?
    a: |
      1. Before you uninstall, close any open Insomnia windows. If any are left open, Insomnia won't uninstall completely.
      1. On your Windows device, go to **Settings > Apps > Installed apps**.
      1. Find Insomnia in the list of installed applications and select the ellipsis (⋯).
      1. Click **Uninstall**.
      1. Click **Finish**.

      To uninstall Insomnia silently, run the uninstaller with the /S flag:
      ```powershell
      "%ProgramFiles%\Insomnia\Uninstall.exe" /S
      ```
  - q: How do I specify a custom directory during a silent install?
    a: |
      To specify a custom directory, add `/D=path`:
      ```powershell
      Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S /D=C:\Insomnia
      ```
  - q: Is the `/D="C:\Program Files\Insomnia"` needed to run the installer?
    a: |
      No. You only need to include the `/D=` option if you want to change the default installation path.  
      If not specified, Insomnia installs to the default location for your installation type: 
      - **System-wide installation**: `C:\Program Files\Insomnia`  
      - **Per-user installation**: `C:\Users\<username>\AppData\Local\Programs\Insomnia`  
      
      Use `/D=your_path` only when you want to specify a custom installation directory.
     
next_steps:
  - text: Get started with documents
    url: /insomnia/documents/
  - text: Get started with collections
    url: /insomnia/collections/

no_wrap: true    
---

Insomnia for Windows uses the **NSIS installer**. Depending on your environment, you can run the installer with GUI, silently, or with administrator privileges. It's also possible to remove Insomnia from the GUI or with a silent uninstall command.

{% navtabs "windows install" %}
{% navtab "Desktop Installer" %}

## Download the installer
Before you install, close any open Insomnia windows. The NSIS installer can't update files that are actively in use.

1. Go to the [latest Insomnia release](https://github.com/Kong/insomnia/releases/tag/core%40{{ site.data.insomnia_latest.version }}) on GitHub.
1. From the **Assets** section, click `Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe` to download the NSIS installer.

## Run the installer
1. From your downloads folder, select the `Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe` file.
2. Click **Yes** to run the installer.

## Follow the setup wizard

Once you've run the installer, you can use the Insomnia setup wizard to complete the installation.

1. Select your preference for the distribution of software, and then select **Next**.
2. In the **Destination Folder** field, enter the install location of the Insomnia file.
3. Click **Install**.
4. Click **Finish**.

{% endnavtab %}
{% navtab "Silent install" %}

## Run the installer
After installing the NSIS installer, run the installer with the `/S` flag to perform a silent installation:
```powershell
Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S
```
{:.info}
> Silent installs use default options unless specifically overridden. To specify a custom directory, add `/D=path`: 
```powershell
Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S /D=C:\Insomnia
```

{% endnavtab %}
{% navtab "Admin deployment" %}

## Run the installer

For system-wide installations, run the installer with administrator privileges:
```powershell
Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S /D="C:\Program Files\Insomnia"
```

{% endnavtab %}

{% endnavtabs %}