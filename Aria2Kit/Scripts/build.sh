#!/bin/bash
set -e
cd "$(dirname "$0")/.."
swift run builder
