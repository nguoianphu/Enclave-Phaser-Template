#!/bin/bash

httpserver900="node --max_old_space_size=900 `which http-server`"
$httpserver900 $1
