#!/usr/bin/env bash

java -jar "/usr/local/share/java/jar/parquet.jar" org.apache.parquet.cli.Main "$@"

# /path/to/parquet-cli-1.9.1-runtime.jar org.apache.parquet.cli.Main --dollar-zero parquet
