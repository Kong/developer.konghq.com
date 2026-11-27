You need Python 3.9 or later and `pip` to run the ingestion script.
Verify your Python version:

```bash
python3 --version
```

1. Create a virtual environment:

   ```bash
   python3 -m venv myenv
   ```

1. Activate it:

   ```bash
   source myenv/bin/activate
   ```

1. Install the required packages:

   ```bash
   python3 -m pip install redis requests langchain-text-splitters
   ```
   {: data-test-prereq="block" }
