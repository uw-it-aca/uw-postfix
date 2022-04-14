#!/bin/bash
set -e

# make sure configmap is mounted
stat /config/main.cf &> /dev/null
