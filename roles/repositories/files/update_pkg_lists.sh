#!/bin/sh

echo "[+] $(date) Starting update of package repositories"
aptitude update
echo "[+] $(date) Ended update of package repositories"

exit 0
