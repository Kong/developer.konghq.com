1. Generate a private key:

    ```sh
    openssl genpkey -algorithm RSA -out my-key.pem
    ```
2. Generate a certificate signing request:

    ```sh
    openssl req -new -key my-key.pem -out my-csr.pem
    ```
3. Create a self-signed certificate:

    ```sh
    openssl x509 -req -in my-csr.pem -signkey my-key.pem -out my-cert.pem -days 365
    ```

4. Create a UUID and export it so the value can be used through the rest of the guide:

    ```sh
    export CERT_ID=$(uuidgen) && echo $CERT_ID
    ```

4. Using the contents of `my-key.pem`, `my-cert.pem`, and the `CERT_ID`, add the 
Certificate to {{site.base_gateway}} using decK:

```sh
echo '
_format_version: "3.0"
certificates:
  - cert: |-
      -----BEGIN CERTIFICATE-----
      MIIDRTCCAi2gAwIBAgIUMJERhwxue4l6zF2if4gcCjdzXKwwDQYJKoZIhvcNAQEL
      BQAwSzELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAk5DMQ8wDQYDVQQHDAZCb3N0b24x
      DTALBgNVBAoMBEtvbmcxDzANBgNVBAMMBm15LXNuaTAeFw0yNTAxMjgxOTQ3MTRa
      Fw0yNjAxMjgxOTQ3MTRaMEsxCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJOQzEPMA0G
      A1UEBwwGQm9zdG9uMQ0wCwYDVQQKDARLb25nMQ8wDQYDVQQDDAZteS1zbmkwggEi
      MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC10bdAm7LZZCq3TAVVvwkKufS1
      1UQ9EsYhnz3isYxxv4zrRaK9jh4GGi8aLJO1/GllCU0oASo9ZWLFLQpjlPsIP9v8
      LeJ9M7B8Kt55+0uxOsv5XmuX1zposGy6Z0lpY9If032bfHhztTQWmIqpuCgmh6r4
      k4x+lArN3T/v6OensmtC6iDEaSHzOo2moAtpD5KFyIIiuOmdWNxcraFNbuWjdOPP
      pv/OUC8ktdGeYoBHzYNNlWXkDufbt0ADC/wzpbvDHT6f2RGZelJttCYm1xm3qDWp
      NTeejEYXevP6Z6zoEeJsCEEju0xInOHWHiAPIze2GdQZ6U0H/4zKtMyDyJdvAgMB
      AAGjITAfMB0GA1UdDgQWBBRI8YKbENL6XqNmRv0MQjNvLzK3GDANBgkqhkiG9w0B
      AQsFAAOCAQEAsIVPxHb1Ll+2KyyftiCKH/dmaeG14MOIp1sVPFbt5DolhBdriFLr
      EVaefttPd4Z3uq11pyhKdhVmjDJ1a9mUJjD5CVrnp5+7D2qw1QNzU8Y9H9Io1LOI
      Uofs1OXoIQI5c+oYUZM7PoD+/hcUKKl2vZ44dcPMYBnhn1qZPn95IqDTMPBcbSm+
      CFiyJ8sF6mF26qaT6gTIbKjOSA9b+XWWJUPpwtUxAd5KjdzbTEmemy3dkeNPQJNM
      HnWQz/VRQEC2md43lRU6KUxhUamXf+boOOMT4k1b8pj3tEcEqY2cW4CZ8qGgEvyr
      4/t5YSkmXGTbbC8QwdK+MxjlPbfVqp9nUg==
      -----END CERTIFICATE-----
    id: 2D22E0CD-55D8-4901-8500-986C6B515CFC
    key: |-
      -----BEGIN PRIVATE KEY-----
      MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC10bdAm7LZZCq3
      TAVVvwkKufS11UQ9EsYhnz3isYxxv4zrRaK9jh4GGi8aLJO1/GllCU0oASo9ZWLF
      LQpjlPsIP9v8LeJ9M7B8Kt55+0uxOsv5XmuX1zposGy6Z0lpY9If032bfHhztTQW
      mIqpuCgmh6r4k4x+lArN3T/v6OensmtC6iDEaSHzOo2moAtpD5KFyIIiuOmdWNxc
      raFNbuWjdOPPpv/OUC8ktdGeYoBHzYNNlWXkDufbt0ADC/wzpbvDHT6f2RGZelJt
      tCYm1xm3qDWpNTeejEYXevP6Z6zoEeJsCEEju0xInOHWHiAPIze2GdQZ6U0H/4zK
      tMyDyJdvAgMBAAECggEAKP2BueAgPyB0/OP3o/AwoqlvwPq2qqor3vKeqhfrGM3d
      gEEvwlpi7G9ExTrdhj7EqBGjwmwY0MSlstxHplG1EpQLDVxu3lkj5apog8mis+8U
      g0DFMvND6Mw1hwS4KTlm6uPsQnyaT0O/3YRAZqjs7FrTsbzaBMNteCH0QysX5tdR
      LNNViuOjfBvqtlNqoMGkxwHxou52xo+Er6vFAlv9+dHUbQfnxwbPQJrDTB/jZDru
      SN7En2bDv9EyWNofahAiy9xFhb9PtclhktdiHQWIhD5ZlxKatoU4YAGe6Qyh2nl9
      3sh7vTfioOwNjE9POzPUxUyCB3ihN9QP+ErR7/gocQKBgQD7N+5zPKcjpNzzZ5Nn
      YK9D55UxFBC6r44iShgYomYvl8spfPfrW4+IFuJDncdB2KezffEJRK1kwp6jHJf+
      2skMpNhjlU7f5ShoxYF3BnGIcKVlXCep++TkezCUHZBmtZgN7FYyvx+rISfYJXCY
      7BH3I0TmJF4NzGBCKNDN1lAX2QKBgQC5R6J0/WbrIUZjVY3qQRlCSZmDzxWE3kMf
      94Mam4bXu05GIinttQ0Xr9RaeaEXYMdE4+Do3GGLTP16BV9z+piTZVLz6/qIHDnO
      I3osnagXmMcBWF0jTNG2PzHpKgEIbRXvuz2ltggu3xbySwIOCGImgxyalYapLUnO
      RgLvpE2khwKBgEGAk+v4JJxmoDXXC9gonYpXF890K+iBXc4TA7VoorxGF/L5Yqs7
      dHFHhjebLBk/JHrom7CO96cOF87v5bHN2h4x3ToZ9DbsyVyIIvml9HRe6sFDBhSM
      WWI5vLDiBITDVKJMvSz+KIO2YW06VeGJrCWETLK1SNDQOUkG22rQNpIBAoGAOjC0
      Zjfb5gcaW0JYgvUVIMuKymn0oTlJLbYH2Ah2rjSmncJHFuAhD4pqkEvY+0Wq8Aj9
      70Sf4ic5COS9GOjgmJJfHjrEAZGT2hksWuzdCSQzhEmjXt3Wk31/iHJnxqS0Ggnd
      j7j/EvF//HLwX0XkxaGyDx7dHy8ZGg7FB0y8EesCgYA1Py0mm6WLMUP6xlXnrlhj
      hzg8ZZ+GB5MZRc2oeKlYPkaRIC3WRd6iXgX58no60ByAzmjimXWvwd9DMJgeAvyW
      ei+z5QAXvWnkAjatMRedOlf26KkKdAax5QDqNbN3DIk+SIbAPWN0ecYag9YQt/m8
      mFmxfVBnyBFNNIj1RMmQrg==
      -----END PRIVATE KEY-----
' | deck gateway apply - 
```