Install kong-harnesses on Linux with [Homebrew](https://brew.sh):

```sh
brew install kong/kong-harnesses/kong-harnesses
```

To install a Linux package instead, download the `.deb` or `.rpm` package for your computer from the kong-harnesses repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`.
Check the package using [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file), then install it.
Replace `FILE` with the package filename:

* Ubuntu: `sudo apt install ./FILE`
* Red Hat Enterprise Linux: `sudo dnf install ./FILE`

Verify the installation:

```sh
kong-harnesses version
```
