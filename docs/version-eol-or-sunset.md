# Managing version End-of-Life (EOL) and End of Sunset support

Instructions for managing docs for EOL and EOS product versions.

## Kong Gateway

Kong Gateway versions have three stages:
* Supported
* Reached end of life (EOL) and entered sunset support
* Reached end of sunset support (EOS)

### Moving an EOL version into sunset support

1. In `app/_data/support/gateway.yml`, ensure that the EOL and sunset dates are correct. 

    * For regular releases, the EOL should be exactly a year after the first minor release (e.g. 3.8.0.0); the sunset date should be exactly two years after.
    For example, if 3.8.0.0 came out on 2024-09-11, the EOL is 2025-09-11, and sunset is 2026-09-11.
    * For LTS releases, the EOL should be exactly three years after the first minor release; the sunset date should be exactly four years after.
    For example, if 3.10.0.0 LTS came out on 2025-03-31, the EOL is 2028-03-31, and sunset is 2029-03-31.

1. In `/app/_data/products/gateway.yml`, find the release and set `sunset: true`. Check the dates and ensure they align to the previous step.

### Moving a sunset version into EOS

When a version moves into end of sunset support, it is completely removed from the doc.

More details TBA when we actually have to do this.
