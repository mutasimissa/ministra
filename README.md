# Ministra Docker Setup

This guide explains how to run Ministra using Docker. No prior Docker experience
required.

---

## Prerequisites

Before you begin, make sure you have Docker installed on your system:

1. **Install Docker Desktop** (includes Docker Compose):
   - **Windows/Mac**: Download from
     [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - **Linux**: Run these commands:
     ```bash
     curl -fsSL https://get.docker.com -o get-docker.sh
     sudo sh get-docker.sh
     ```

2. **Verify installation** by opening a terminal and running:
   ```bash
   docker --version
   docker compose version
   ```
   You should see version numbers for both.

---

## 1. Starting for the First Time

Follow these steps to start Ministra for the first time:

### Step 1: Add the Ministra Installation File (Required!)

You must place the original **Ministra 5.6.10 zip file** in this folder:

1. Obtain the official `ministra.zip` file (Ministra 5.6.10)
2. Copy or move it to this project folder
3. Make sure the file is named exactly `ministra.zip`

**Without this file, Ministra will not work!**

### Step 2: Configure Credentials

All credentials are managed through a single `.env` file. **You never need to
edit `compose.yml` or `custom.ini` directly.**

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` in any text editor and set your own secure passwords:
   ```env
   MYSQL_ROOT_PASSWORD=your_secure_root_password
   MYSQL_DATABASE=ministra
   MYSQL_USER=ministra
   MYSQL_PASSWORD=your_secure_user_password

   MINISTRA_PORT=8080
   ```
3. Save the file

**Note:** The `.env` file is gitignored and will not be committed to version
control. The `custom.ini` database credentials are automatically patched from
these values at container startup.

### Step 3: Open Terminal

- **Windows**: Open PowerShell or Command Prompt
- **Mac**: Open Terminal (Applications → Utilities → Terminal)
- **Linux**: Open your terminal application

### Step 4: Navigate to the Project Folder

```bash
cd /path/to/ministra
```

Replace `/path/to/ministra` with the actual path where you saved this project.

### Step 5: Make the Init Script Executable (Linux/Mac only)

```bash
chmod +x scripts/01-init.sh scripts/init-ministra.sh
```

### Step 6: Start All Services

```bash
docker compose up -d
```

**What this does:**

- Downloads the required images (first time only, may take a few minutes)
- Creates and starts three containers: `ministra`, `mysql`, and `memcache`
- The `-d` flag runs everything in the background

### Step 7: Wait for MySQL to Initialize

The first startup takes about 30-60 seconds while MySQL sets up the database.
You can check progress with:

```bash
docker compose logs -f mysql
```

Press `Ctrl+C` to stop watching logs.

### Step 8: Access Ministra

Open your web browser and go to:

```
http://localhost:8080
```

---

## 2. Stopping the Containers (The Right Way)

To gracefully stop all containers without losing any data:

```bash
docker compose stop
```

**What this does:**

- Sends a shutdown signal to each container
- Waits for them to finish what they're doing
- Stops all containers but keeps them and their data intact

To start them again later:

```bash
docker compose start
```

### Alternative: Stop and Remove Containers (Keeps Data)

```bash
docker compose down
```

**What this does:**

- Stops all containers
- Removes the containers (but NOT your data)
- Your database and files are safe in `mysql_data/` and `storage/`

To start again after `down`:

```bash
docker compose up -d
```

---

## 3. Recreating Containers After Making Edits

If you edit configuration files (like `.env`, `compose.yml`, `custom.ini`,
etc.), you need to recreate the containers:

### If You Changed `.env` or `compose.yml`:

```bash
docker compose up -d
```

Docker will automatically detect changes and recreate only the affected
containers.

### If You Changed Other Config Files:

```bash
docker compose restart
```

### Force Full Recreate (When in Doubt):

```bash
docker compose down
docker compose up -d
```

### Rebuild with Latest Image:

If a new version of the Ministra image is available:

```bash
docker compose pull
docker compose up -d
```

---

## 4. Destroy Everything and Rebuild from Scratch

**WARNING: This will DELETE all your data including the database!**

### Step 1: Stop and Remove All Containers

```bash
docker compose down
```

### Step 2: Delete the Database Files

```bash
rm -rf mysql_data
```

### Step 3: Delete Storage Files (Optional)

Only do this if you want to remove all stored content:

```bash
rm -rf storage
```

### Step 4: Start Fresh

```bash
docker compose up -d
```

**What happens:**

- New empty database is created
- MySQL init script runs again to set up users and database
- Everything starts as if it's a brand new installation

### Nuclear Option: Remove Everything Including Images

If you want to completely clean up Docker:

```bash
docker compose down --rmi all --volumes
rm -rf mysql_data storage
docker compose up -d
```

---

## 5. Backup Your Data

### Quick Backup (Database + Storage)

#### Backup Database:

```bash
docker compose exec mysql mysqldump -u root -proot_password ministra > backup_$(date +%Y%m%d_%H%M%S).sql
```

This creates a file like `backup_20260118_131500.sql` in your current folder.

#### Backup Storage Files:

```bash
tar -czvf storage_backup_$(date +%Y%m%d_%H%M%S).tar.gz storage/
```

### Restore Database from Backup:

```bash
docker compose exec -T mysql mysql -u root -proot_password ministra < backup_20260118_131500.sql
```

Replace `backup_20260118_131500.sql` with your actual backup filename.

### Restore Storage Files:

```bash
rm -rf storage
tar -xzvf storage_backup_20260118_131500.tar.gz
```

### Full Backup Script

Create a file called `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Backing up database..."
docker compose exec -T mysql mysqldump -u root -proot_password ministra > $BACKUP_DIR/db_$DATE.sql

echo "Backing up storage..."
tar -czvf $BACKUP_DIR/storage_$DATE.tar.gz storage/

echo "Backup complete! Files saved to $BACKUP_DIR/"
```

Make it executable and run:

```bash
chmod +x backup.sh
./backup.sh
```

---

## Troubleshooting

### Check if Containers are Running:

```bash
docker compose ps
```

### View Container Logs:

```bash
# All containers
docker compose logs

# Specific container
docker compose logs ministra
docker compose logs mysql

# Follow logs in real-time
docker compose logs -f
```

### Container Won't Start:

1. Check logs: `docker compose logs`
2. Try recreating: `docker compose down && docker compose up -d`
3. Check if ports are in use: `sudo lsof -i :8080` or `sudo lsof -i :3306`

### Database Connection Issues:

Wait 30-60 seconds after first start. Check MySQL logs:

```bash
docker compose logs mysql
```

### Reset Everything:

```bash
docker compose down
rm -rf mysql_data
docker compose up -d
```

---

## Quick Reference

| Action                     | Command                                                                             |
| -------------------------- | ----------------------------------------------------------------------------------- |
| Start services             | `docker compose up -d`                                                              |
| Stop services              | `docker compose stop`                                                               |
| Stop and remove containers | `docker compose down`                                                               |
| View running containers    | `docker compose ps`                                                                 |
| View logs                  | `docker compose logs`                                                               |
| Restart services           | `docker compose restart`                                                            |
| Backup database            | `docker compose exec mysql mysqldump -u root -proot_password ministra > backup.sql` |

---

## Configuration

### Credentials

All credentials are defined in `.env` (copied from `.env.example`). You never
need to edit `compose.yml` or `custom.ini` directly — the init script patches
`custom.ini` automatically from the environment variables.

### Ports

- **Ministra Web Interface**: `http://localhost:<MINISTRA_PORT>` (default
  `8080`)
- **MySQL**: `3306` (internal only)

### Important Files

- `.env.example` - Template for environment variables (copy to `.env`)
- `.env` - Your local credentials (gitignored)
- `compose.yml` - Docker Compose configuration
- `custom.ini` - Ministra settings (DB credentials patched automatically)
- `scripts/` - Init scripts (MySQL + Ministra)
- `mysql.conf.d/` - MySQL configuration
- `mysql_data/` - Database files (auto-created)
- `storage/` - Ministra storage files
