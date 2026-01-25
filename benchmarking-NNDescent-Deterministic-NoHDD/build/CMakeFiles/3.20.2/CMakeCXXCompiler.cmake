set(CMAKE_CXX_COMPILER "/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/compilers/bin/nvc++")
set(CMAKE_CXX_COMPILER_ARG1 "")
set(CMAKE_CXX_COMPILER_ID "NVHPC")
set(CMAKE_CXX_COMPILER_VERSION "24.5.1")
set(CMAKE_CXX_COMPILER_VERSION_INTERNAL "")
set(CMAKE_CXX_COMPILER_WRAPPER "")
set(CMAKE_CXX_STANDARD_COMPUTED_DEFAULT "14")
set(CMAKE_CXX_COMPILE_FEATURES "cxx_std_98;cxx_template_template_parameters;cxx_std_11;cxx_alias_templates;cxx_alignas;cxx_alignof;cxx_attributes;cxx_auto_type;cxx_constexpr;cxx_decltype;cxx_decltype_incomplete_return_types;cxx_default_function_template_args;cxx_defaulted_functions;cxx_defaulted_move_initializers;cxx_delegating_constructors;cxx_deleted_functions;cxx_enum_forward_declarations;cxx_explicit_conversions;cxx_extended_friend_declarations;cxx_extern_templates;cxx_final;cxx_func_identifier;cxx_generalized_initializers;cxx_inheriting_constructors;cxx_inline_namespaces;cxx_lambdas;cxx_local_type_template_args;cxx_long_long_type;cxx_noexcept;cxx_nonstatic_member_init;cxx_nullptr;cxx_override;cxx_range_for;cxx_raw_string_literals;cxx_reference_qualified_functions;cxx_right_angle_brackets;cxx_rvalue_references;cxx_sizeof_member;cxx_static_assert;cxx_strong_enums;cxx_thread_local;cxx_trailing_return_types;cxx_unicode_literals;cxx_uniform_initialization;cxx_unrestricted_unions;cxx_user_literals;cxx_variadic_macros;cxx_variadic_templates;cxx_std_14;cxx_aggregate_default_initializers;cxx_attribute_deprecated;cxx_binary_literals;cxx_contextual_conversions;cxx_decltype_auto;cxx_digit_separators;cxx_generic_lambdas;cxx_lambda_init_captures;cxx_relaxed_constexpr;cxx_return_type_deduction;cxx_variable_templates;cxx_std_17")
set(CMAKE_CXX98_COMPILE_FEATURES "cxx_std_98;cxx_template_template_parameters")
set(CMAKE_CXX11_COMPILE_FEATURES "cxx_std_11;cxx_alias_templates;cxx_alignas;cxx_alignof;cxx_attributes;cxx_auto_type;cxx_constexpr;cxx_decltype;cxx_decltype_incomplete_return_types;cxx_default_function_template_args;cxx_defaulted_functions;cxx_defaulted_move_initializers;cxx_delegating_constructors;cxx_deleted_functions;cxx_enum_forward_declarations;cxx_explicit_conversions;cxx_extended_friend_declarations;cxx_extern_templates;cxx_final;cxx_func_identifier;cxx_generalized_initializers;cxx_inheriting_constructors;cxx_inline_namespaces;cxx_lambdas;cxx_local_type_template_args;cxx_long_long_type;cxx_noexcept;cxx_nonstatic_member_init;cxx_nullptr;cxx_override;cxx_range_for;cxx_raw_string_literals;cxx_reference_qualified_functions;cxx_right_angle_brackets;cxx_rvalue_references;cxx_sizeof_member;cxx_static_assert;cxx_strong_enums;cxx_thread_local;cxx_trailing_return_types;cxx_unicode_literals;cxx_uniform_initialization;cxx_unrestricted_unions;cxx_user_literals;cxx_variadic_macros;cxx_variadic_templates")
set(CMAKE_CXX14_COMPILE_FEATURES "cxx_std_14;cxx_aggregate_default_initializers;cxx_attribute_deprecated;cxx_binary_literals;cxx_contextual_conversions;cxx_decltype_auto;cxx_digit_separators;cxx_generic_lambdas;cxx_lambda_init_captures;cxx_relaxed_constexpr;cxx_return_type_deduction;cxx_variable_templates")
set(CMAKE_CXX17_COMPILE_FEATURES "cxx_std_17")
set(CMAKE_CXX20_COMPILE_FEATURES "")
set(CMAKE_CXX23_COMPILE_FEATURES "")

set(CMAKE_CXX_PLATFORM_ID "Linux")
set(CMAKE_CXX_SIMULATE_ID "")
set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT "")
set(CMAKE_CXX_SIMULATE_VERSION "")




set(CMAKE_AR "/usr/bin/ar")
set(CMAKE_CXX_COMPILER_AR "")
set(CMAKE_RANLIB "/usr/bin/ranlib")
set(CMAKE_CXX_COMPILER_RANLIB "")
set(CMAKE_LINKER "/usr/bin/ld")
set(CMAKE_MT "")
set(CMAKE_COMPILER_IS_GNUCXX )
set(CMAKE_CXX_COMPILER_LOADED 1)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_CXX_ABI_COMPILED TRUE)
set(CMAKE_COMPILER_IS_MINGW )
set(CMAKE_COMPILER_IS_CYGWIN )
if(CMAKE_COMPILER_IS_CYGWIN)
  set(CYGWIN 1)
  set(UNIX 1)
endif()

set(CMAKE_CXX_COMPILER_ENV_VAR "CXX")

if(CMAKE_COMPILER_IS_MINGW)
  set(MINGW 1)
endif()
set(CMAKE_CXX_COMPILER_ID_RUN 1)
set(CMAKE_CXX_SOURCE_FILE_EXTENSIONS C;M;c++;cc;cpp;cxx;m;mm;mpp;CPP)
set(CMAKE_CXX_IGNORE_EXTENSIONS inl;h;hpp;HPP;H;o;O;obj;OBJ;def;DEF;rc;RC)

foreach (lang C OBJC OBJCXX)
  if (CMAKE_${lang}_COMPILER_ID_RUN)
    foreach(extension IN LISTS CMAKE_${lang}_SOURCE_FILE_EXTENSIONS)
      list(REMOVE_ITEM CMAKE_CXX_SOURCE_FILE_EXTENSIONS ${extension})
    endforeach()
  endif()
endforeach()

set(CMAKE_CXX_LINKER_PREFERENCE 30)
set(CMAKE_CXX_LINKER_PREFERENCE_PROPAGATES 1)

# Save compiler ABI information.
set(CMAKE_CXX_SIZEOF_DATA_PTR "8")
set(CMAKE_CXX_COMPILER_ABI "")
set(CMAKE_CXX_BYTE_ORDER "LITTLE_ENDIAN")
set(CMAKE_CXX_LIBRARY_ARCHITECTURE "")

if(CMAKE_CXX_SIZEOF_DATA_PTR)
  set(CMAKE_SIZEOF_VOID_P "${CMAKE_CXX_SIZEOF_DATA_PTR}")
endif()

if(CMAKE_CXX_COMPILER_ABI)
  set(CMAKE_INTERNAL_PLATFORM_ABI "${CMAKE_CXX_COMPILER_ABI}")
endif()

if(CMAKE_CXX_LIBRARY_ARCHITECTURE)
  set(CMAKE_LIBRARY_ARCHITECTURE "")
endif()

set(CMAKE_CXX_CL_SHOWINCLUDES_PREFIX "")
if(CMAKE_CXX_CL_SHOWINCLUDES_PREFIX)
  set(CMAKE_CL_SHOWINCLUDES_PREFIX "${CMAKE_CXX_CL_SHOWINCLUDES_PREFIX}")
endif()





set(CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES "/usr/include")
set(CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "atomic;nvhpcatm;stdc++;nvomp;dl;nvhpcatm;atomic;pthread;nvcpumath;nsnvc;nvc;gcc;c;gcc_s;m")
set(CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES "/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/python-3.11.6-i5k3c6ggftqkzgqyymfbkynpgm2lgjtd/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/util-linux-uuid-2.38.1-jkdi7kvvma7367qdmvpkada4pyiafoud/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/sqlite-3.43.2-casyrltocz5edzjhs5vzlqhwkamn7y4a/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libxcrypt-4.4.35-ss2rzin25ozjy4gyy3dack36njs6navg/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libffi-3.4.4-6r7brdq5dnreoad6f7sn7ybjjvwdmvue/lib64;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libffi-3.4.4-6r7brdq5dnreoad6f7sn7ybjjvwdmvue/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/gettext-0.22.3-2g7elifkgxzpypbswqnjuu5hefn4mjts/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/zstd-1.5.5-gawytflrhedqdc2riwax7oduoqddx22s/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libxml2-2.10.3-5eeeokp4kszufozbayq4bewwmyeuwy27/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/zlib-ng-2.1.4-6htiapkoa6fx2medhyabzo575skozuir/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/xz-5.4.1-hubmwr5wc5nf6zk3ghuaikxiejuyt6bi/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libiconv-1.17-d7yvx2s6da4x2rfx44bc3perbb33rvuy/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/gdbm-1.23-fs6otcki47azeywcckquj2sy4mzsnzxg/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/readline-8.2-nyw6mp6b7dvizewrf7exopvap2q32s5j/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/ncurses-6.4-asx3jea367shsxjt6bdj2bu5olxll6ni/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/expat-2.5.0-bptl3xwbvbkxxoc5x3dhviorarv4dvxv/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libbsd-0.11.7-cgxjopleu7se4y4cgi7oefbljgasr457/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/libmd-1.0.4-wja3f5q3w75tqtro333fptfnji7oqxiu/lib;/leonardo/prod/spack/5.2/install/0.21/linux-rhel8-icelake/gcc-8.5.0/bzip2-1.0.8-gp5wcz5lksrbm2gqiqjppumrhjz6gahy/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/12.4/hpcx/hpcx-2.19/ucx/mt/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/comm_libs/12.4/hpcx/hpcx-2.19/ompi/lib;/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/compilers/lib;/usr/lib64;/usr/lib/gcc/x86_64-redhat-linux/8")
set(CMAKE_CXX_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES "")
