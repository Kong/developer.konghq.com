Install PostgreSQL using the following steps:

{% navtabs "Linux Install" -%}
{%- navtab "Ubuntu" %}
1. Update the package list:

   ```sh
   sudo apt update
   ```

1. Install PostgreSQL:

   ```sh
   sudo apt install -y postgresql postgresql-contrib
   ```

1. Enable PostgreSQL to start on boot:

   ```sh
   sudo systemctl enable postgresql
   ```
{% endnavtab %}
{% navtab "Red Hat" %}

1. Enable the PostgreSQL module and install PostgreSQL 15:

   ```sh
   sudo dnf module list postgresql
   sudo dnf module enable postgresql:15 -y
   ```

2. Install PostgreSQL server and contrib packages:

   ```sh
   sudo dnf install -y postgresql-server
   ```

3. Initialize the PostgreSQL database:

   ```sh
   sudo systemctl enable postgresql
   sudo systemctl start postgresql
   ```
{%- endnavtab -%}
{%- endnavtabs -%}