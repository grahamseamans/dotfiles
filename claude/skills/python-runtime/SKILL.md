---
name: python-runtime
description: How to run Python code and manage packages.
user-invocable: false
---

# Python Runtime

Always use `uv` to run Python. This lets you include whatever packages you need inline without installing anything globally.

```bash
uv run --with requests python script.py
uv run --with pandas --with numpy python analyze.py
```

Do not use system Python. Do not pip install. Do not create virtualenvs manually. Just `uv run --with` and go.
