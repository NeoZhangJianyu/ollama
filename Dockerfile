# vim: filetype=dockerfile

ARG FLAVOR=${TARGETARCH}


ARG ROCMVERSION=6.3.3
ARG JETPACK5VERSION=r35.4.1
ARG JETPACK6VERSION=r36.4.0
ARG CMAKEVERSION=3.31.2

ARG TARGET_ARCH=x86_64
ARG INTEL_DL_ESS=2025.1.0-0-devel-ubuntu24.04

## Build Image

FROM intel/deep-learning-essentials:$INTEL_DL_ESS AS base
ENV http_proxy http://proxy.ims.intel.com:911
ENV https_proxy http://proxy.ims.intel.com:911
ARG TARGETARCH
RUN echo "TARGETARCH ${TARGETARCH}"


ARG GGML_SYCL_F16=OFF
ARG CMAKEVERSION
ARG TARGET_ARCH

RUN echo "Install packages by apt " && apt-get update && \
    apt-get install -y git libcurl4-openssl-dev curl wget vim ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKEVERSION}/cmake-${CMAKEVERSION}-linux-${TARGET_ARCH}.tar.gz | tar xz -C /usr/local --strip-components 1
COPY CMakeLists.txt CMakePresets.json .
COPY ml/backend/ggml/ggml ml/backend/ggml/ggml
ENV LDFLAGS=-s

RUN echo $(cmake --version)
# RUN echo "Building with dynamic libs" && \
#     mkdir -p build && \
#     cmake --preset 'SYCL' -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx -DGGML_SYCL=ON -DGGML_SYCL_TARGET=INTEL && \
#     cmake --build --parallel --preset 'SYCL' && \
#     cmake --install build --component SYCL --strip

    #cmake -B build -DGGML_NATIVE=OFF -DGGML_SYCL=ON -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx -DLLAMA_CURL=ON -DGGML_SYCL_TARGET=INTEL && \
    # cmake --build build --config Release -j

# FROM ${TARGETARCH} AS base
# ENV http_proxy http://proxy.ims.intel.com:911
# ENV https_proxy http://proxy.ims.intel.com:911

# ARG CMAKEVERSION
# ARG TARGET_ARCH
# RUN curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKEVERSION}/cmake-${CMAKEVERSION}-linux-${TARGET_ARCH}.tar.gz | tar xz -C /usr/local --strip-components 1
# COPY CMakeLists.txt CMakePresets.json .
# COPY ml/backend/ggml/ggml ml/backend/ggml/ggml
# ENV LDFLAGS=-s

FROM base AS cpu
RUN --mount=type=cache,target=/root/.ccache \
    cmake --preset 'CPU' \
        && cmake --build --parallel --preset 'CPU' \
        && cmake --install build --component CPU --strip --parallel 8


FROM base AS sycl
RUN --mount=type=cache,target=/root/.ccache \
    cmake --preset 'SYCL' -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx -DGGML_SYCL=ON -DGGML_SYCL_TARGET=INTEL \
        && cmake --build --parallel --preset 'SYCL'  \
        && cmake --install build --component SYCL --strip --parallel 8


FROM base AS build
WORKDIR /go/src/github.com/ollama/ollama
COPY go.mod go.sum .
RUN curl -fsSL https://golang.org/dl/go$(awk '/^go/ { print $2 }' go.mod).linux-$(case $(uname -m) in x86_64) echo amd64 ;; aarch64) echo arm64 ;; esac).tar.gz | tar xz -C /usr/local
ENV PATH=/usr/local/go/bin:$PATH
RUN go mod download
COPY . .
ARG GOFLAGS="'-ldflags=-w -s'"
ENV CGO_ENABLED=1
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -buildmode=pie -o /bin/ollama .

# FROM --platform=linux/amd64 scratch AS amd64
COPY --from=sycl dist/lib/ollama/sycl /lib/ollama/sycl



FROM base AS archive

RUN echo "archive"
COPY --from=cpu dist/lib/ollama /lib/ollama
# COPY --from=build /bin/ollama /bin/ollama

FROM base AS app
RUN echo "from base"
# COPY --from=archive /bin /usr/bin
# ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY --from=archive /lib/ollama /usr/lib/ollama
# #ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV ONEAPI_DEVICE_SELECTOR="level_zero:0"
# #ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
# #ENV NVIDIA_VISIBLE_DEVICES=all
ENV OLLAMA_HOST=0.0.0.0:11434
EXPOSE 11434
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"]

# ENTRYPOINT ["/bin/bash"]
