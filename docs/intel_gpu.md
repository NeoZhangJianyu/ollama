# Intel GPU

- Background

Intel GPU support is not merged to Ollama official release. Please following the method in this guide.


## Linux

- Only for Ubuntu 22 and newer release.

### Install Intel GPU driver.

Intel Data Center GPUs drivers installation guide: [Get intel dGPU Drivers](https://dgpu-docs.intel.com/driver/installation.html#ubuntu-install-steps).

Intel Client GPUs *(iGPU & Arc A/B-Series)*, please refer to the [client GPU driver installation](https://dgpu-docs.intel.com/driver/client/overview.html).

Once installed, add the user(s) to the `video` and `render` groups.

```sh
sudo usermod -aG render $USER
sudo usermod -aG video $USER
```

*Note*: logout/re-login for the changes to take effect.

Verify installation through `clinfo`:

```sh
sudo apt install clinfo
sudo clinfo -l
```

Sample output:

```sh
Platform #0: Intel(R) OpenCL Graphics
 `-- Device #0: Intel(R) Arc(TM) A770 Graphics

Platform #0: Intel(R) OpenCL HD Graphics
 `-- Device #0: Intel(R) Iris(R) Xe Graphics [0x9a49]
```

### Install Ollama

```
git clone https://github.com/NeoZhangJianyu/ollama
cd ollama
./script/install.sh
```

You will see following log if everything is OK:

```
tar: lib/ollama/sycl: time stamp xxxx is xxxx s in the future
>>> Adding ollama user to render group...
>>> Adding ollama user to video group...
>>> Adding current user to ollama group...
>>> Creating ollama systemd service...
>>> Set for Intel GPU
>>> Enabling and starting ollama service...
>>> The Ollama API is now available at 127.0.0.1:11434.
>>> Install complete. Run "ollama" from the command line.
>>> Intel GPU ready.
```

### Uninstall Ollama

```
./scripts/uninstall.sh
```

### Check Status

#### Check Ollama Service Status
```
sudo systemctl status ollama.service

[sudo] password for zzz:
ollama.service - Ollama Service
     Loaded: loaded (/etc/systemd/system/ollama.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat xxx CST; 1h 4min ago
   Main PID: 1926627 (ollama)
      Tasks: 16 (limit: 76665)
     Memory: 201.8M
        CPU: 3.416s
     CGroup: /system.slice/ollama.service
             1926627 /usr/local/bin/ollama serve

xxx 12:17:20 arc770-tce ollama[1926627]: llama_init_from_model:  SYCL_Host compute buffer size =    17.13 MiB
xxx 12:17:20 arc770-tce ollama[1926627]: llama_init_from_model: graph nodes  = 966
xxx 12:17:20 arc770-tce ollama[1926627]: llama_init_from_model: graph splits = 2
```

#### Check Intel GPU to Be Detected

The Intel GPU info will be shown in following log:

```
vi /var/log/syslog

ollama[2027516]: time=2025-05-10T13:23:32.508+08:00 level=INFO source=gpu.go:217 msg="looking for compatible GPUs"
ollama[2027516]: time=2025-05-10T13:23:32.573+08:00 level=INFO source=types.go:130 msg="inference compute" id=0 library=sycl variant="" compute="" driver=0.0 name="Intel(R) Arc(TM) A770 Graphics" total="15.9 GiB" available="15.1 GiB"
ollama[2027516]: time=2025-05-10T13:23:32.573+08:00 level=INFO source=types.go:130 msg="inference compute" id=1 library=sycl variant="" compute="" driver=0.0 name="Intel(R) UHD Graphics 770" total="0 B" available="0 B"
```

#### Sanity Test

In terminal:

```
ollama run smollm:135m

>>> hi
Hello! How can I help you?
```

#### Set Proxy

```
sudo vi /etc/systemd/system/ollama.service

Environment="https_proxy=http://proxy.xxx.yyy:8080"
```

Restart Ollama Service:

```
sudo systemctl daemon-reload && sudo systemctl restart ollama.service

```
#### Check SYCL Backend of GGML Is Enabled.

Check the "SYCL" in following log:

```
tail -f /var/log/syslog

ollama[2055516]: llama_init_from_model:  SYCL_Host  output buffer size =     0.76 MiB
ollama[2055516]: llama_init_from_model:      SYCL0 compute buffer size =   164.50 MiB
ollama[2055516]: llama_init_from_model:  SYCL_Host compute buffer size =    17.13 MiB

```

#### Check the Used GPU

```
vi /var/log/syslog

ollama[2866937]: Found 1 SYCL devices:
...
ollama[2866937]: | 0| [level_zero:gpu:0]|                Intel Arc A770 Graphics|  12.55|    512|    1024|   32| 16225M|         1.6.32567+18|

```

### Usage

Note: after update the ollama.service file, you must restart the Ollama server to enable it.

Restart Ollama Service:

```
sudo systemctl daemon-reload && sudo systemctl restart ollama.service

```

- Use special Intel GPU

There would be more than one Intel GPU in PC. Like iGPU + dGPU.

Set the special GPU by following method.

In this example, use GPU #1:

```
sudo vi /etc/systemd/system/ollama.service

Environment="ONEAPI_DEVICE_SELECTOR=level_zero:1"

```
Restore Ollama service.


Note, it's possible to runn LLM on both iGPU and dGPU.

Set `Environment="ONEAPI_DEVICE_SELECTOR=level_zero:0;level_zero:1"`.

It can't improve the performance, but support bigger LLM.

- Disable Intel GPU in Ollama

There would be more than one GPU in PC. Like Intel iGPU + Other dGPU.

You could disable Intel GPU to use other GPU.

```
sudo vi /etc/systemd/system/ollama.service

Environment="OLLAMA_DISABLE_INTEL_GPU=1"
```
Restore Ollama service.

- Debug

```
sudo vi /etc/systemd/system/ollama.service

Environment="OLLAMA_DEBUG=1"
```
Restore Ollama service.

### Build from Source Code

- Install Docker

You need to install Docker before it.

If you need set proxy to access internet, please add https_proxy in Dockerfile:

```
vi Dockerfile

ENV https_proxy http://proxy.xxx.com:8080
```

- Build Ollama for Intel GPU

```
./scripts/build_linux.sh
```

- Check output in folder "dist"

```
ls dist

bin  lib  ollama-linux-amd64-sycl.tgz  ollama-linux-amd64.tgz
```

- Install to Local

```
./scripts/local_install.sh
```

### Windows

#### Install GPU driver

Intel GPU drivers instructions guide and download page can be found here: [Get intel GPU Drivers](https://www.intel.com/content/www/us/en/products/docs/discrete-gpus/arc/software/drivers.html).


Coming soon!


## Q&A

- I meet the following error:

```
>>> hi
Error: POST predict: Post "http://127.0.0.1:38339/completion": EOF
```

A: It's known issue after restart Ollama service with the changed config file: /etc/systemd/system/ollama.service and .

Please try again! After several times, it will disappear. Maybe the root cause is the load dynamic library issue.

- Can I use multiple GPUs in my machine?

A: Yes. Ollama use ggml SYCL backend to support Intel GPU. It supports multiple GPUs as default.

But it's serial model, instead of parallel model. That means the multiple GPUs can load bigger model, instead of speeding up the inference.

It only supports Intel GPUs, instead of mix vendors.

You could assign the multiple GPUs by:

`Environment="ONEAPI_DEVICE_SELECTOR=level_zero:0;level_zero:1;level_zero:2"`.

Recommend to use the GPUs with same mode. That only reduce 5% performance.

If mix Intel iGPU and dGPU, the whole process will be impacted by the low performance of iGPU.

- How I can confirm multiple GPUs to be used?

A: Check the log `vi /var/log/syslog`'

You will see similar info for 2 GPUs are used:

```
ollama[2118444]: load_tensors:        SYCL0 model buffer size =    13.33 MiB
ollama[2118444]: load_tensors:        SYCL1 model buffer size =    72.49 MiB
```
