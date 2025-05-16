cmake_minimum_required(VERSION 3.21)

project(Ollama C CXX)

include(CheckLanguage)

find_package(Threads REQUIRED)

set(CMAKE_BUILD_TYPE Release)
set(BUILD_SHARED_LIBS ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(GGML_BUILD ON)
set(GGML_SHARED ON)
set(GGML_CCACHE ON)
set(GGML_BACKEND_DL ON)
set(GGML_BACKEND_SHARED ON)
set(GGML_SCHED_MAX_COPIES 4)

set(GGML_LLAMAFILE ON)
set(GGML_CUDA_PEER_MAX_BATCH_SIZE 128)
set(GGML_CUDA_GRAPHS ON)
set(GGML_CUDA_FA ON)
set(GGML_CUDA_COMPRESSION_MODE default)

if((CMAKE_OSX_ARCHITECTURES AND NOT CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
    OR (NOT CMAKE_OSX_ARCHITECTURES AND NOT CMAKE_SYSTEM_PROCESSOR MATCHES "arm|aarch64|ARM64|ARMv[0-9]+"))
    set(GGML_CPU_ALL_VARIANTS ON)
endif()

if (CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
    set(CMAKE_BUILD_RPATH "@loader_path")
    set(CMAKE_INSTALL_RPATH "@loader_path")
endif()

set(OLLAMA_BUILD_DIR ${CMAKE_BINARY_DIR}/lib/ollama)
set(OLLAMA_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/lib/ollama)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY         ${OLLAMA_BUILD_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG   ${OLLAMA_BUILD_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${OLLAMA_BUILD_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY         ${OLLAMA_BUILD_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG   ${OLLAMA_BUILD_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${OLLAMA_BUILD_DIR})

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ml/backend/ggml/ggml/src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ml/backend/ggml/ggml/src/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ml/backend/ggml/ggml/src/ggml-cpu)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ml/backend/ggml/ggml/src/ggml-cpu/amx)

set(GGML_CPU ON)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/ml/backend/ggml/ggml/src)
set_property(TARGET ggml PROPERTY EXCLUDE_FROM_ALL TRUE)

get_target_property(CPU_VARIANTS ggml-cpu MANUALLY_ADDED_DEPENDENCIES)
if(NOT CPU_VARIANTS)
    set(CPU_VARIANTS "ggml-cpu")
endif()

install(TARGETS ggml-base ${CPU_VARIANTS}
    RUNTIME_DEPENDENCIES
        PRE_EXCLUDE_REGEXES ".*"
    RUNTIME DESTINATION ${OLLAMA_INSTALL_DIR} COMPONENT CPU
    LIBRARY DESTINATION ${OLLAMA_INSTALL_DIR} COMPONENT CPU
    FRAMEWORK DESTINATION ${OLLAMA_INSTALL_DIR} COMPONENT CPU
)

if (DEFINED ENV{ONEAPI_ROOT})
    find_package(IntelSYCL REQUIRED)
    message(STATUS ${CMAKE_C_COMPILER})
    message(STATUS ${CMAKE_CXX_COMPILER})

    check_cxx_compiler_flag("-fsycl" SUPPORTS_SYCL)
    if(SUPPORTS_SYCL)
        message(STATUS "SYCL found")
        set(SYCL_PLATFORM "intel")

        set(MKLROOT "$ENV{MKLROOT}")
        set(CMPLR_ROOT "$ENV{CMPLR_ROOT}")
        set(DNNLROOT "$ENV{DNNLROOT}")
        set(TBBROOT "$ENV{TBBROOT}")
        set(UMF_ROOT "$ENV{UMF_ROOT}")

        #message(STATUS ${MKLROOT}/lib)
        # message(STATUS ${DNNLROOT}/lib)
        # message(STATUS ${TBBROOT}/lib)

        # message(STATUS "$ENV{LD_LIBRARY_PATH}")

        set(OLLAMA_SYCL_INSTALL_DIR ${OLLAMA_INSTALL_DIR}/sycl)

        install(TARGETS ggml-sycl
            RUNTIME_DEPENDENCIES
                DIRECTORIES ${TBBROOT}/lib/ ${DNNLROOT}/lib ${MKLROOT}/lib ${CMPLR_ROOT}/lib  ${UMF_ROOT}/lib
                PRE_INCLUDE_REGEXES  hwloc dnnl mkl_sycl_blas mkl_intel_ilp64 mkl_tbb_thread mkl_core sycl imf svml irng  intlc ur_loader
                PRE_EXCLUDE_REGEXES ".*"
                POST_EXCLUDE_REGEXES
                    [=[.*system32\/.*\.dll]=]
                    [=[^\/(lib|usr\/lib|usr\/local\/lib)]=]
            RUNTIME DESTINATION ${OLLAMA_SYCL_INSTALL_DIR} COMPONENT SYCL
            LIBRARY DESTINATION ${OLLAMA_SYCL_INSTALL_DIR} COMPONENT SYCL
            FRAMEWORK DESTINATION ${OLLAMA_SYCL_INSTALL_DIR} COMPONENT SYCL
        )

        file(COPY
                ${TBBROOT}/lib/intel64/gcc4.8/libtbb.so
                DESTINATION ${OLLAMA_SYCL_INSTALL_DIR}
                FOLLOW_SYMLINK_CHAIN
              )
        file(COPY
              ${CMPLR_ROOT}/lib/libur_adapter_level_zero.so
              DESTINATION ${OLLAMA_SYCL_INSTALL_DIR}
              FOLLOW_SYMLINK_CHAIN
            )
        file(COPY
            ${CMPLR_ROOT}/lib/libOpenCL.so
            DESTINATION ${OLLAMA_SYCL_INSTALL_DIR}
            FOLLOW_SYMLINK_CHAIN
          )
        file(COPY
          ${UMF_ROOT}/lib/libumf.so
          DESTINATION ${OLLAMA_SYCL_INSTALL_DIR}
          FOLLOW_SYMLINK_CHAIN
        )
        file(COPY
          ${UMF_ROOT}/lib/libdisjoint_pool.a
          DESTINATION ${OLLAMA_SYCL_INSTALL_DIR}
          FOLLOW_SYMLINK_CHAIN
        )


    else()
        message(FATAL_ERROR, "C++ compiler lacks SYCL support.")
    endif()
else()
    message(STATUS, "Skip to build SYCL, miss to detect SYCL support.")
endif()


