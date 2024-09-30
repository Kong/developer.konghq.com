{% assign summary = 'inso-cli' %}

{% capture details_content %}
  The [Inso CLI (Command Line Interface)](/inso-cli/) allows you to use Insomnia application functionality in your terminal and CI/CD environments for automation.
  To complete this tutorial you will need to install Inso CLI:
  1. Download the package for your OS:
    * [macOS](https://updates.insomnia.rest/downloads/mac/latest?app=com.insomnia.inso&channel=stable)
    * [Windows](https://updates.insomnia.rest/downloads/windows/latest?app=com.insomnia.inso&channel=stable)
    * [Linux](https://docs.insomnia.rest/inso-cli/install#:~:text=tar%20file%20from-,GitHub,-.%20Extract%20the%20file)
  1. Extract the package:
    * macOS: 
        ```sh
        tar -xf inso-macos-2.4.1.zip
        ```
    * Windows:
        ```sh
        tar -xf inso-windows-2.4.1.zip
        ```
    * Linux: 
        ```sh
        tar -xf inso-linux-2.4.1.tar.xz
        ```
  1. Check that Inso CLI was installed correctly:
            
            ./inso --version

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}