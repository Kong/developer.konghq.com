def main():
    setup_environment()
    
    # Run all enable plugin tests
    test_enable_rate_limiting_plugin_admin_api()
    test_enable_rate_limiting_plugin_konnect()
    test_enable_rate_limiting_plugin_deck()
    test_enable_rate_limiting_plugin_kubernetes()

    # Run validation test
    test_validate_rate_limiting_plugin()

    # Teardown environment
    teardown_environment()

if __name__ == "__main__":
    main()


    