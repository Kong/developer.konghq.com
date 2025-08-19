Kong provides Compressor service as a private Docker image in a Cloudsmith repository. Contact [Kong Support](https://support.konghq.com/support/s/) to get access to it.

Once you've received your Cloudsmith access token, run the following commands in Docker to pull the image:

1. To pull images, you must authenticate first with the token provided by the Support:

    ```bash
    docker login docker.cloudsmith.io
    ```

2. Docker will then prompt you to enter username and password:

    ```bash
    Username: kong/ai-compress
    Password: <YOUR_TOKEN>
    ```

    {:.info}
    > This is a token-based login with read-only access. You can pull images but not push them. Contact support for your token.

3. To pull an image:

    Replace `<image-name>` and `<tag>` with the appropriate image and version, such as:

    ```bash
    docker pull docker.cloudsmith.io/kong/ai-compress/service:v0.0.3
    ```

4. You can now run the image by pasting the following command in Docker:

    ```bash
    docker run --rm -p 8080:8080 docker.cloudsmith.io/kong/ai-compress/service:v0.0.3
    ```
