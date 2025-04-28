#!/bin/bash

LOCAL_IP=$(ip addr | grep 'inet 192.168' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
echo "VITE_BACKEND_IP=${LOCAL_IP}" > .env