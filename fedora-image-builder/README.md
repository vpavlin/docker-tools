# Fedora Image Builder

Simple bash script that let's you create a Docker base image in similar way to how they are built in [Koji](http://kojipkgs.fedoraproject.org/mash/rawhide-20150111/rawhide/$arch/os/) - Fedora's buildsystem. It uses virt-install and virsh commands internally.

I wrote this script because you cannot easily test changes in KS file without running a build in Koji (for what I don't have a permission).

## Usage

To build latest rawhide image simply run

```
# ./build.sh
```

You can specify kickstart file with *--kickstart* option (either local path URL), install tree to build from with *--repo*, name of the built image with *--name* and path to the image file (*--disk*) which will be used as a storage for the VM where the anaconda and kickstart will run.
