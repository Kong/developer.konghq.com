---
title: Download Insomnia on a Windows

content_type: how_to

products:
- insomnia

description: Learn how to install Insomnia on a Windows device.

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
  a: Learn how to download Insomnia.

---

From version 11.3.0, Insomnia for Windows now uses the Nullsoft Scriptable Install System (NSIS) installer. This update gives you more control over your setup by allowing you to choose the installation directory that best suits your system. Install Insomnia using the NSIS installer on a Windows device. To install and run Insomnia on Windows, your system must be Windows 10 or later.

> Before you install, you must close any open Insomnia windows. The NSIS installer cannot update files that are actively in use, which can cause an incomplete installation.
{:.warning}

To download Insomnia onto a Windows device, complete the following steps:

## Download the installer
1. Go to the [Insomnia Downloads page](https://insomnia.rest/download).
2. Select **Download for Windows**.
3. When the download is complete, locate the file named: **Insomnia.Core-nsis-\<version\>.exe**.

> The filename follows the format `Insomnia.Core-nsis-<version>.exe`. The actual version number, for example, `11.3.0` changes as updates are released. Always download the latest version from the [Insomnia Downloads page](https://insomnia.rest/download).
{:.info}

## Run the installer
1. From your downloads folder, select the **Insomnia.Core-nsis-\<version\>.exe** file.
2. Select **Yes**.

## Follow the setup wizard
1. Select your preference for the distribution of software, and then select **Next >**.
2. In the **Destination Folder** box, enter the install location of the Insomnia file.
3. Select **Install**.
4. Select **Finish**.
