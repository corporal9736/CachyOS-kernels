# CachyOS-kernels
Overlay containing ebuilds of CachyOS kernels and some other things

## Adding the overlay
``` sh
eselect repository add CachyOS-kernels git https://github.com/corporal9736/CachyOS-kernels
```

## Sync overlay
``` sh
emaint sync -r CachyOS-kernels
```
## Compile with LTO and BTF

Please note that you may need raise `vm.max_map_count` when compiling this kernel with both LTO and BTF information. You can temporarily set this by `sudo sysctl -w vm.max_map_count=262144`, or permanently, write `vm.max_map_count=262144` to /etc/sysctl.conf.  
