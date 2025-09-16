---
title: Download Insomnia on Windows

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
  - q: What installer does Insomnia use to install on Windows devices?
    a: Starting in version 11.3.0, Insomnia for Windows provides the Nullsoft Scriptable Install System (NSIS) installer. This update gives you more control over your setup by allowing you to choose the installation directory that best suits your system.
  - q: How do I uninstall Insomnia from my Windows device?
    a: |
      1. Before you uninstall, close any open Insomnia windows. If any are left open, Insomnia won't uninstall completely.
      1. On your Windows device, go to **Settings > Apps > Installed apps**.
      1. Find Insomnia in the list of installed applications and select the ellipsis (⋯).
      1. Click **Uninstall**.
      1. Click **Finish**.
next_steps:
  - text: Get started with documents
    url: /insomnia/documents/
  - text: Get started with collections
    url: /insomnia/collections/
---

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
