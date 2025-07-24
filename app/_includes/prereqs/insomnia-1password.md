This guide requires a [1Password account](https://support.1password.com/explore/get-started/).

1. Once you have an account, follow the steps in the [1Password docs](https://developer.1password.com/docs/cli/get-started) to install 1Password CLI on the same system as Insomnia.
1. Create a vault:
   ```sh
   op vault create insomnia
   ```
1. Create a secret:
   ```sh
   op item create --category=login --title='test-secret' --vault='insomnia' \
    password='my-password'
   ```