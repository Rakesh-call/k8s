#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with 'sudo'."
  exit 1
fi

echo "=========================================="
echo "      Ready-to-Use User & CSR Creator     "
echo "=========================================="

# 1. Ask for Inputs
read -p "Enter Username: " USERNAME
read -p "Enter Group Name: " GROUPNAME
read -s -p "Enter Password for $USERNAME: " PASSWORD
echo "" 

# Validation
if [ -z "$USERNAME" ] || [ -z "$GROUPNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Error: Username, Group, and Password cannot be empty!"
    exit 1
fi

# 2. Create Group if it doesn't exist
if getent group "$GROUPNAME" > /dev/null 2>&1; then
    echo "Group '$GROUPNAME' already exists."
else
    groupadd "$GROUPNAME"
    echo "Group '$GROUPNAME' created successfully."
fi

# 3. Create User
if id "$USERNAME" > /dev/null 2>&1; then
    echo "Error: User '$USERNAME' already exists!"
    exit 1
else
    useradd -m -g "$GROUPNAME" -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "User '$USERNAME' created and added to group '$GROUPNAME'."
fi

# 4. Generate CSR in Background
echo "Generating CSR in the background..."
TARGET_DIR="/home/$USERNAME/certs"
mkdir -p "$TARGET_DIR"

# OpenSSL details (Default values)
COUNTRY="IN"
STATE="Rajasthan"
LOCATION="Jaipur"
ORGANIZATION="MyCompany"
ORG_UNIT="IT"
COMMON_NAME="$USERNAME.local"

openssl req -new -newkey rsa:2048 -nodes \
  -keyout "$TARGET_DIR/$USERNAME.key" \
  -out "$TARGET_DIR/$USERNAME.csr" \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$COMMON_NAME" > /dev/null 2>&1

# Fix permissions
chown -R "$USERNAME:$GROUPNAME" "$TARGET_DIR"
chmod 700 "$TARGET_DIR"
chmod 600 "$TARGET_DIR/$USERNAME.key"

echo "=========================================="
echo "SUCCESS!"
echo "User and Group are ready."
echo "CSR File: $TARGET_DIR/$USERNAME.csr"
echo "Key File: $TARGET_DIR/$USERNAME.key"
echo "=========================================="
