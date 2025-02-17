```bash
docker exec {{include.container}} kong vault get {{include.secret}} 
```