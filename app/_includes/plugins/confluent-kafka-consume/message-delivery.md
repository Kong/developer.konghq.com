When running multiple data plane nodes, there is no thread-safe behavior between nodes. In high-load scenarios, you may observe the same message being delivered multiple times across different data plane nodes.

To minimize duplicate message delivery in a multi-node setup, consider:
* Using a single data plane node for consuming messages from specific topics
* Implementing idempotency handling in your consuming application
* Monitoring Consumer Group offsets across your data plane nodes