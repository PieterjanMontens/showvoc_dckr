# Showvoc docker server
Single docker environment for [showvoc](http://showvoc.uniroma2.it/doc/), using sources available at https://bitbucket.org/art-uniroma2/showvoc/src/master/

This version uses Nginx to serve the static contents and provide reverse proxy to the Apache Karaf instance of Semantic Turkey.

## Install
- Build & Run Dockerfile

## Config
- volumes : mount persistent data volume on `/opt/data`
