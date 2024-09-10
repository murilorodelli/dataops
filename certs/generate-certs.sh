#!/bin/bash

openssl req \
    -newkey rsa:4096 -nodes -sha256 -keyout tls.key \
    -x509 -days 3650 -out tls.crt \
    -config san.cnf
