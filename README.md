# Kubernetes Simple Deployment Shell Script for debian/ubuntu

Testing using Debian 11 and Ubuntu 22.04

## usage

For mainland China, please use zh-cn. 

For other regions, please use general.

1. Configure `/etc/hosts` first.
2. Execute `sudo bash debianinit.sh`.
3. Execute `sudo bash debianinit.sh`.
4. Execute `bash kuber.sh`.
5. Then，edit `kubeadm-config.yaml` according to your specific requirements.
6. run `kubeadm init --config kubeadm-config.yaml`



```
Note:
The above four steps should be executed on all nodes. 
Then configure the control-plane and node according to your specific requirements.
```

