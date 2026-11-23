1. On the **Program** page, keep the install and uninstall commands that Intune reads from the installer.
1. In the **Install behavior** section, select **System**.
1. From the **Device restart behavior** dropdown menu, select “No specific action”.
   This setting prevents the installation from restarting the device.
1. Click **Next**.
1. On the **Requirements** page, in the **Check operating system architecture** section, select **Yes. Specify the systems the app can be installed on.**
1. Select the **Install on x64 system** checkbox for `_windows_amd64.msi`, or select the **Install on ARM64 system** checkbox for `_windows_arm64.msi`.
   Leave every other architecture checkbox cleared, because the two installers replace each other.
1. From the **Minimum operating system** dropdown menu, select the oldest Windows 11 release in the list.
   kong-harnesses doesn't support Windows 10.
1. Click **Next**.
1. On the **Detection rules** page, from the **Rules format** dropdown menu, select “Manually configure detection rules”.
1. Click **Add**.
1. From the **Rule type** dropdown menu, select “MSI”.
   Keep the product code that Intune reads from the installer.
1. Click **OK**.
1. Click **Next**.
1. On the **Dependencies** page, click **Next**.
