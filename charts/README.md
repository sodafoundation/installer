# soda-helm
This is an installation tool for soda using [helm](https://github.com/kubernetes/helm).
With different charts folder shown below, we provide a simplified and flexible way to
deploy soda cluster.

## soda
`soda` charts is designed for deploying soda controller and dock modules in one
command:
```shell
helm install soda/ --name={ service_name } --namespace={ kubernetes_namespace }
```

## csiplugin-block
`csiplugin-block` charts is designed for deploying soda csi block plugin module in one command:
```shell
helm install csiplugin-block/ --name={ service_name } --namespace={ kubernetes_namespace }
```

## csiplugin-file
`csiplugin-file` charts is designed for deploying soda csi file plugin module in one command:
```shell
helm install csiplugin-file/ --name={ service_name } --namespace={ kubernetes_namespace }
```

## servicebroker
`servicebroker` charts is designed for deploying soda servicebroker module in one
command:
```shell
helm install servicebroker/ --name={ service_name } --namespace={ kubernetes_namespace }
```
