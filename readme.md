
## 编译

### 编译rootless版本
make clean && make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1

### 编译rootful版本
make clean && make package FINALPACKAGE=1