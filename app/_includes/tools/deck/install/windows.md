If you are on Windows, you can either use the compressed archive from the [Github release page](https://github.com/kong/deck/releases) or install using CMD by entering the target installation folder and downloading a compressed archive, which contains the binary.

1.  ```bash
    curl -sL https://github.com/kong/deck/releases/download/v{{site.data.deck_latest.version}}/deck_{{site.data.deck_latest.version}}_windows_amd64.tar.gz -o deck.tar.gz
    ```
2.  ```bash
    mkdir deck
    ```
3.  ```bash
    tar -xf deck.tar.gz -C deck
    ```
4.  ```bash
    powershell -command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + [IO.Path]::PathSeparator + [System.IO.Directory]::GetCurrentDirectory() + '\deck', 'User')"
    ```
