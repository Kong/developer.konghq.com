Install PostgreSQL on Ubuntu using the following steps:

1. Update the package list:
```sh
sudo apt update
```

2. Install PostgreSQL:
```sh
sudo apt install -y postgresql postgresql-contrib
```

3. Enable PostgreSQL to start on boot:
```sh
sudo systemctl enable postgresql
```
