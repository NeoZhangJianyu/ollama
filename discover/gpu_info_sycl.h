#ifndef __APPLE__
#ifndef __GPU_INFO_ONEAPI_H__
#define __GPU_INFO_ONEAPI_H__
#include "gpu_info.h"


typedef struct sycl_handle {
  void *handle;
  uint16_t verbose;

  void (*ggml_backend_sycl_get_device_memory)(int device, size_t *free,
                                                  size_t *total);
  int (*ggml_backend_sycl_get_device_count)();
  void (*ggml_backend_sycl_get_device_description)(int device,
                                                   char *description,
                                                   size_t description_size);

} sycl_handle_t;

typedef struct sycl_init_resp {
  char *err; // If err is non-null handle is invalid
  sycl_handle_t oh;
} sycl_init_resp_t;

void sycl_init(char *sycl_lib_path, sycl_init_resp_t *resp);
void sycl_get_device_info(sycl_init_resp_t *resp, int device,
    mem_info_t *res_mem_info);
void sycl_release(sycl_init_resp_t *resp);
int sycl_get_device_count(sycl_init_resp_t *resp);

#endif // __GPU_INFO_INTEL_H__
#endif // __APPLE__
