<!--vale off-->

## Prerequisites

Make sure python3 and pipenv are installed:

1. Install `python3`:

    ```
    brew install python3
    ```

2. Install `pipenv`:

    ```
    python3 -m pip install pipenv
    ```

## Setup

We're using a fork of `shot-scraper` that adds support for reusable macros and persistent Chrome authentication.

```
git clone https://github.com/kong-product-org/shot-scraper
cd shot-scraper
python3 -m pipenv shell
pip install -e .
```

You'll need to run `python3 -m pipenv shell` any time you want to use the tool.

## Authentication

Konnect requires authentication before it will show you the pages you need.

The fork supports persistent Chrome authentication via your existing Chrome profile, so you don't need to log in every time.

### Option 1: Persistent Chrome profile (recommended)

Set the `SHOT_SCRAPER_CHROME_PROFILE` environment variable to your Chrome profile directory:

**macOS:**
```bash
export SHOT_SCRAPER_CHROME_PROFILE="$HOME/Library/Application Support/Google/Chrome/Default"
```

**Linux:**
```bash
export SHOT_SCRAPER_CHROME_PROFILE="$HOME/.config/google-chrome/Default"
```

Then run auth once to open Chrome and log in to Konnect:

```bash
shot-scraper auth https://cloud.konghq.com auth.json
```

Press `<enter>` once you see the Konnect dashboard. Your session is saved in your Chrome profile and will persist across runs.

### Option 2: Auth file (fallback)

If you don't set `SHOT_SCRAPER_CHROME_PROFILE`, the tool falls back to file-based auth:

```bash
shot-scraper auth https://cloud.konghq.com /tmp/auth.json
```

## Usage

Run the following command to regenerate screenshots:

```bash
cd tools/screenshots
shot-scraper multi --macro macros.yaml MY_SCREENSHOTS_FILE.yaml
```

If using the auth file fallback, pass `-a` with the path:

```bash
shot-scraper multi -a /tmp/auth.json --macro macros.yaml MY_SCREENSHOTS_FILE.yaml
```

## Debugging

To see the browser while capturing screenshots, set the `SHOT_SCRAPER_CHROME_PROFILE` env var (see above). The persistent context runs in non-headless mode by default when used interactively.
