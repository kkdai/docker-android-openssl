# docker-android-openssl

Dockerfile to build openssl 1.0.2d on android api 19


How to use it
-------------------

```shell
  git clone https://github.com/kkdai/docker-android-openssl.git
  
  #build docker image
  docker build -t kkdai/android-openssl .  
  
  #setting docker output volume
  docker run -v //c/Users/YOUR_NAME/FOLDER:output --rm=true kkdai/android-openssl
  
  #Get all openssl library in //c/Users/YOUR_NAME/FOLDER
```
