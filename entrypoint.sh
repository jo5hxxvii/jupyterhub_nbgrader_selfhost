#!/bin/bash
for d in /home/*/; do
  u=$(basename "$d")
  uid=$(stat -c %u "$d")
  if ! id "$u" >/dev/null 2>&1; then
    if [ "$uid" -ge 1000 ]; then
      useradd -M -d "/home/$u" -s /bin/bash -u "$uid" "$u" 2>/dev/null
    else
      useradd -M -d "/home/$u" -s /bin/bash "$u" 2>/dev/null
    fi
  fi
done
exec jupyterhub -f /etc/jupyterhub/jupyterhub_config.py