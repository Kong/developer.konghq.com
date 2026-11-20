Install kong-harnesses on Linux with [Homebrew](https://brew.sh):

```sh
brew install kong/kong-harnesses/kong-harnesses
```

To install a Linux package instead, download the `.deb` or `.rpm` package for your computer from the kong-harnesses repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`, then install it:

* Ubuntu: `sudo apt install ./<file>.deb`
* Red Hat Enterprise Linux: `sudo dnf install ./<file>.rpm`

Verify the installation:

```sh
kong-harnesses version
```
