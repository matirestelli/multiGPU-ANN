set(CMAKE_CUDA_COMPILER "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/compilers/bin/nvcc")
set(CMAKE_CUDA_HOST_COMPILER "")
set(CMAKE_CUDA_HOST_LINK_LAUNCHER "/usr/bin/g++")
set(CMAKE_CUDA_COMPILER_ID "NVIDIA")
set(CMAKE_CUDA_COMPILER_VERSION "11.8.89")
set(CMAKE_CUDA_DEVICE_LINKER "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/bin/nvlink")
set(CMAKE_CUDA_FATBINARY "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/bin/fatbinary")
set(CMAKE_CUDA_STANDARD_COMPUTED_DEFAULT "14")
set(CMAKE_CUDA_COMPILE_FEATURES "cuda_std_03;cuda_std_11;cuda_std_14;cuda_std_17")
set(CMAKE_CUDA03_COMPILE_FEATURES "cuda_std_03")
set(CMAKE_CUDA11_COMPILE_FEATURES "cuda_std_11")
set(CMAKE_CUDA14_COMPILE_FEATURES "cuda_std_14")
set(CMAKE_CUDA17_COMPILE_FEATURES "cuda_std_17")
set(CMAKE_CUDA20_COMPILE_FEATURES "")
set(CMAKE_CUDA23_COMPILE_FEATURES "")

set(CMAKE_CUDA_PLATFORM_ID "Linux")
set(CMAKE_CUDA_SIMULATE_ID "GNU")
set(CMAKE_CUDA_COMPILER_FRONTEND_VARIANT "")
set(CMAKE_CUDA_SIMULATE_VERSION "8.5")



set(CMAKE_CUDA_COMPILER_ENV_VAR "CUDACXX")
set(CMAKE_CUDA_HOST_COMPILER_ENV_VAR "CUDAHOSTCXX")

set(CMAKE_CUDA_COMPILER_LOADED 1)
set(CMAKE_CUDA_COMPILER_ID_RUN 1)
set(CMAKE_CUDA_SOURCE_FILE_EXTENSIONS cu)
set(CMAKE_CUDA_LINKER_PREFERENCE 15)
set(CMAKE_CUDA_LINKER_PREFERENCE_PROPAGATES 1)

set(CMAKE_CUDA_SIZEOF_DATA_PTR "8")
set(CMAKE_CUDA_COMPILER_ABI "ELF")
set(CMAKE_CUDA_BYTE_ORDER "LITTLE_ENDIAN")
set(CMAKE_CUDA_LIBRARY_ARCHITECTURE "")

if(CMAKE_CUDA_SIZEOF_DATA_PTR)
  set(CMAKE_SIZEOF_VOID_P "${CMAKE_CUDA_SIZEOF_DATA_PTR}")
endif()

if(CMAKE_CUDA_COMPILER_ABI)
  set(CMAKE_INTERNAL_PLATFORM_ABI "${CMAKE_CUDA_COMPILER_ABI}")
endif()

if(CMAKE_CUDA_LIBRARY_ARCHITECTURE)
  set(CMAKE_LIBRARY_ARCHITECTURE "")
endif()

set(CMAKE_CUDA_COMPILER_TOOLKIT_ROOT "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8")
set(CMAKE_CUDA_COMPILER_TOOLKIT_LIBRARY_ROOT "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8")
set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8")

set(CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/targets/x86_64-linux/include")

set(CMAKE_CUDA_HOST_IMPLICIT_LINK_LIBRARIES "")
set(CMAKE_CUDA_HOST_IMPLICIT_LINK_DIRECTORIES "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/lib64;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/math_libs/11.8/lib64;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/11.8/nccl/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/11.8/nvshmem/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/targets/x86_64-linux/lib/stubs;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/targets/x86_64-linux/lib")
set(CMAKE_CUDA_HOST_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES "")

set(CMAKE_CUDA_IMPLICIT_INCLUDE_DIRECTORIES "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/math_libs/11.8/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/11.8/nccl/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/11.8/nvshmem/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/12.4/hpcx/hpcx-2.19/ucx/mt/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/math_libs/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/nccl/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/nvshmem/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/compilers/extras/qd/include/qd;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/python-3.11.6-i5k3c6ggftqkzgqyymfbkynpgm2lgjtd/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/util-linux-uuid-2.38.1-jkdi7kvvma7367qdmvpkada4pyiafoud/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/sqlite-3.43.2-casyrltocz5edzjhs5vzlqhwkamn7y4a/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libxcrypt-4.4.35-ss2rzin25ozjy4gyy3dack36njs6navg/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libffi-3.4.4-6r7brdq5dnreoad6f7sn7ybjjvwdmvue/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/gettext-0.22.3-2g7elifkgxzpypbswqnjuu5hefn4mjts/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/zstd-1.5.5-gawytflrhedqdc2riwax7oduoqddx22s/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libxml2-2.10.3-5eeeokp4kszufozbayq4bewwmyeuwy27/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/zlib-ng-2.1.4-6htiapkoa6fx2medhyabzo575skozuir/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/xz-5.4.1-hubmwr5wc5nf6zk3ghuaikxiejuyt6bi/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libiconv-1.17-d7yvx2s6da4x2rfx44bc3perbb33rvuy/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/gdbm-1.23-fs6otcki47azeywcckquj2sy4mzsnzxg/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/readline-8.2-nyw6mp6b7dvizewrf7exopvap2q32s5j/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/ncurses-6.4-asx3jea367shsxjt6bdj2bu5olxll6ni/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/expat-2.5.0-bptl3xwbvbkxxoc5x3dhviorarv4dvxv/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libbsd-0.11.7-cgxjopleu7se4y4cgi7oefbljgasr457/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libmd-1.0.4-wja3f5q3w75tqtro333fptfnji7oqxiu/include;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/bzip2-1.0.8-gp5wcz5lksrbm2gqiqjppumrhjz6gahy/include;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/12.4/hpcx/hpcx-2.19/ompi/include;/usr/include/c++/8;/usr/include/c++/8/x86_64-redhat-linux;/usr/include/c++/8/backward;/usr/lib/gcc/x86_64-redhat-linux/8/include;/usr/local/include;/usr/include")
set(CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES "stdc++;m;gcc_s;gcc;c;gcc_s;gcc")
set(CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/lib64;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/math_libs/11.8/lib64;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/11.8/nccl/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/11.8/nvshmem/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/targets/x86_64-linux/lib/stubs;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/11.8/targets/x86_64-linux/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libffi-3.4.4-6r7brdq5dnreoad6f7sn7ybjjvwdmvue/lib64;/usr/lib/gcc/x86_64-redhat-linux/8;/usr/lib64;/lib64;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/python-3.11.6-i5k3c6ggftqkzgqyymfbkynpgm2lgjtd/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/util-linux-uuid-2.38.1-jkdi7kvvma7367qdmvpkada4pyiafoud/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/sqlite-3.43.2-casyrltocz5edzjhs5vzlqhwkamn7y4a/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libxcrypt-4.4.35-ss2rzin25ozjy4gyy3dack36njs6navg/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libffi-3.4.4-6r7brdq5dnreoad6f7sn7ybjjvwdmvue/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/gettext-0.22.3-2g7elifkgxzpypbswqnjuu5hefn4mjts/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/zstd-1.5.5-gawytflrhedqdc2riwax7oduoqddx22s/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libxml2-2.10.3-5eeeokp4kszufozbayq4bewwmyeuwy27/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/zlib-ng-2.1.4-6htiapkoa6fx2medhyabzo575skozuir/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/xz-5.4.1-hubmwr5wc5nf6zk3ghuaikxiejuyt6bi/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libiconv-1.17-d7yvx2s6da4x2rfx44bc3perbb33rvuy/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/gdbm-1.23-fs6otcki47azeywcckquj2sy4mzsnzxg/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/readline-8.2-nyw6mp6b7dvizewrf7exopvap2q32s5j/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/ncurses-6.4-asx3jea367shsxjt6bdj2bu5olxll6ni/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/expat-2.5.0-bptl3xwbvbkxxoc5x3dhviorarv4dvxv/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libbsd-0.11.7-cgxjopleu7se4y4cgi7oefbljgasr457/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libmd-1.0.4-wja3f5q3w75tqtro333fptfnji7oqxiu/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/bzip2-1.0.8-gp5wcz5lksrbm2gqiqjppumrhjz6gahy/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/12.4/hpcx/hpcx-2.19/ucx/mt/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/12.4/hpcx/hpcx-2.19/ompi/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/compilers/lib;/usr/lib")
set(CMAKE_CUDA_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES "")

set(CMAKE_CUDA_RUNTIME_LIBRARY_DEFAULT "STATIC")

set(CMAKE_LINKER "/usr/bin/ld")
set(CMAKE_AR "/usr/bin/ar")
set(CMAKE_MT "")
