#ifndef __APPLE__

#include "gpu_info_sycl.h"

#include <string.h>

#define LOG_BUF_LEN 1024

void sycl_init(char *sycl_lib_path, sycl_init_resp_t *resp) {
  resp->err = NULL;
  const int buflen = 256;
  char buf[buflen + 1];
  int i, d;
  struct lookup {
    char *s;
    void **p;
  } l[] = {
      {"ggml_backend_sycl_get_device_memory", (void *)&resp->oh.ggml_backend_sycl_get_device_memory},
      {"ggml_backend_sycl_get_device_count", (void *)&resp->oh.ggml_backend_sycl_get_device_count},
      {"ggml_backend_sycl_get_device_description", (void *)&resp->oh.ggml_backend_sycl_get_device_description},
      {NULL, NULL},
  };

  resp->oh.handle = LOAD_LIBRARY(sycl_lib_path, RTLD_LAZY);
  if (!resp->oh.handle) {
    char *msg = LOAD_ERR();
    snprintf(buf, buflen,
             "Unable to load %s library to query for Intel GPUs: %s\n",
             sycl_lib_path, msg);
    free(msg);
    resp->err = strdup(buf);
    return;
  }

  // TODO once we've squashed the remaining corner cases remove this log
  LOG(resp->oh.verbose,
      "wiring ggml sycl library functions in %s\n",
      sycl_lib_path);

  for (i = 0; l[i].s != NULL; i++) {
    // TODO once we've squashed the remaining corner cases remove this log
    LOG(resp->oh.verbose, "dlsym: %s\n", l[i].s);

    *l[i].p = LOAD_SYMBOL(resp->oh.handle, l[i].s);
    if (!*(l[i].p)) {
      resp->oh.handle = NULL;
      char *msg = LOAD_ERR();
      LOG(resp->oh.verbose, "dlerr: %s\n", msg);
      UNLOAD_LIBRARY(resp->oh.handle);
      snprintf(buf, buflen, "symbol lookup for %s failed: %s", l[i].s, msg);
      free(msg);
      resp->err = strdup(buf);
      return;
    }
  }
  return;
}

void format_str(char* buf, int buf_len, uint64_t num) {
    if (num<1000000) {
        snprintf(buf, buf_len, "[%0.2f KB]", num/1000.0);
        return;
    } else if (num<1000000000) {
        snprintf(buf, buf_len, "[%0.2f MB]", num/1000000.0);
        return;
    } else {
        snprintf(buf, buf_len, "[%0.2f GB]", num/1000000000.0);
        return;
    }

}
void sycl_get_device_info(sycl_init_resp_t *resp, int device,
                       mem_info_t *res_mem_info) {
  res_mem_info->err = NULL;
  uint64_t totalMem = 0;
  uint64_t usedMem = 0;
  const int buflen = 256;
  char buf[buflen + 1];
  int i, d, m;

  sycl_handle_t h = resp->oh;

  if (h.handle == NULL) {
    res_mem_info->err = strdup("ggml sycl handle not initialized");
    return;
  }

  if (device < 0  || device >= 24) {
    res_mem_info->err = strdup("driver of device index out of bounds [0-23]");
    return;
  }

  res_mem_info->total = 0;
  res_mem_info->free = 0;

  resp->oh.ggml_backend_sycl_get_device_description(device, &res_mem_info->gpu_name[0], GPU_NAME_LEN);


  snprintf(&res_mem_info->gpu_id[0], GPU_ID_LEN, "%d", device);

  size_t free_mem = 0;
  size_t total_mem = 0;
  resp->oh.ggml_backend_sycl_get_device_memory(device, &free_mem, &total_mem);
  res_mem_info->total = total_mem;
  res_mem_info->free = free_mem;

  char str_total[LOG_BUF_LEN];
  char str_free[LOG_BUF_LEN];

  format_str(str_total, LOG_BUF_LEN-1, total_mem);
  format_str(str_free, LOG_BUF_LEN-1, free_mem);

  LOG(h.verbose, "Detect GPU [%d]-[%s] Mem: Free %s Total %s\n",
    device, res_mem_info->gpu_name, str_free, str_total);
}

void sycl_release(sycl_init_resp_t *resp) {
  int d;
  sycl_handle_t h = resp->oh;
  LOG(h.verbose, "releasing sycl library\n");
  UNLOAD_LIBRARY(h.handle);
  h.handle = NULL;
}

int sycl_get_device_count(sycl_init_resp_t *resp) {
  if (resp->oh.handle == NULL) {
    return 0;
  }

  return resp->oh.ggml_backend_sycl_get_device_count();
}

#endif // __APPLE__
