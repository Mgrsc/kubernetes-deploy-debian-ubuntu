# Kubernetes Simple Deployment Shell Script for debian/ubuntu

Testing using Debian 11 and Ubuntu 22.04

kubeadm deploy kubernetes

## usage

For mainland China, please use cn-zh. 

For other regions, please use general.

1. Configure `/etc/hosts` first.
2. Execute `sudo bash init.sh`.
3. Execute `sudo bash debianinit.sh`.
4. Execute `bash kuber.sh`.
5. Then，edit `kubeadm-config.yaml` according to your specific requirements.
6. run `kubeadm init --config kubeadm-config.yaml`



```
Note:
1.Be sure to change the node name before doing the configuration, otherwise kubectl get node will not be displayed after adding the node
2.The above four steps should be executed on all nodes.
3.Then configure the control-plane and node according to your specific requirements.
4.With the flannel network plugin be sure to set --pod-network-cidr=10.244.0.0/16
```

## 用法

对于中国大陆，请使用cn-zh。

对于其他地区，请使用general。

1. 首先在`/etc/hosts`中进行配置。
2. 执行`sudo bash init.sh`。
3. 执行`sudo bash debianinit.sh`。
4. 执行`bash kuber.sh`。
5. 然后，根据您的特定要求编辑`kubeadm-config.yaml`。
6. 运行`kubeadm init --config kubeadm-config.yaml`

```
注意：
1.在进行配置之前一定要修改节点名称，否则加入节点后kubectl get node无法显示
2.以上四个步骤都应在所有节点上执行。 
3.然后，根据您的具体要求配置控制平面和节点。
4.使用flannel网络插件一定要设置--pod-network-cidr=10.244.0.0/16
```

