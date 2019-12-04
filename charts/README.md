# opensds-helm
This is an installation tool for opensds using [helm](https://github.com/kubernetes/helm).
With different charts folder shown below, we provide a simplified and flexible way to
deploy OpenSDS cluster.

## opensds
`opensds` charts is designed for deploying opensds controller and dock modules in one
command:
```shell
helm install opensds/ --name={ service_name } --namespace={ kubernetes_namespace }
```

## csiplugin-block
`csiplugin-block` charts is designed for deploying opensds csi block plugin module in one command:
```shell
helm install csiplugin-block/ --name={ service_name } --namespace={ kubernetes_namespace }
```

## csiplugin-file
`csiplugin-file` charts is designed for deploying opensds csi file plugin module in one command:
```shell
helm install csiplugin-file/ --name={ service_name } --namespace={ kubernetes_namespace }
```

## servicebroker
`servicebroker` charts is designed for deploying opensds servicebroker module in one
command:
```shell
helm install servicebroker/ --name={ service_name } --namespace={ kubernetes_namespace }
```
