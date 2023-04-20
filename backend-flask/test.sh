#!/bin/bash

bin_path=$(cd `dirname $0` && pwd)
abs_path=$(readlink -f "$0" )

echo $bin_path
echo $abs_path
# /workspace/aws-bootcamp-cruddur-2023/backend-flask/test.sh
echo $(dirname $abs_path)
