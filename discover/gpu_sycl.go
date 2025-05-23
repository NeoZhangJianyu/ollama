//go:build linux || windows

package discover

import (
	"log/slog"
	"strings"
	"os"
)

func syclGetVisibleDevicesEnv(gpuInfo []GpuInfo) (string, string) {

	host_selector := os.Getenv("ONEAPI_DEVICE_SELECTOR")
	if host_selector != "" {
		slog.Info("syclGetVisibleDevicesEnv", "Detect host ONEAPI_DEVICE_SELECTOR, return it directly", host_selector)
		return "ONEAPI_DEVICE_SELECTOR", host_selector
	}

	ids := []string{}
	slog.Info("gpuinfo","len", len(gpuInfo))
	for _, info := range gpuInfo {
		if info.Library != "sycl" {
			// TODO shouldn't happen if things are wired correctly...
			slog.Debug("syclGetVisibleDevicesEnv skipping over non-sycl device", "library", info.Library)
			continue
		}
		ids = append(ids, info.ID)
	}
	result := "level_zero:" + strings.Join(ids, ",")
	slog.Info("syclGetVisibleDevicesEnv", "Not detect host ONEAPI_DEVICE_SELECTOR, set it by detected GPU list", result)

	return "ONEAPI_DEVICE_SELECTOR", result
}
