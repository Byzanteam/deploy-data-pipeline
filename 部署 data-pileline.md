

## 安装 docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh --mirror Aliyun
systemctl enable docker && systemctl start docker
docker login registry.cn-hangzhou.aliyuncs.com

vim /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.io",
    "https://mirror.baidubce.com",
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}

systemctl daemon-reload && systemctl restart docker
```

##  安装 k8s

```bash
wget -c https://sealyun.oss-cn-beijing.aliyuncs.com/latest/sealos && chmod +x sealos && mv sealos /usr/bin

wget -c https://sealyun.oss-cn-beijing.aliyuncs.com/7b6af025d4884fdd5cd51a674994359c-1.18.0/kube1.18.0.tar.gz

sealos init --passwd 123456 \
  --master 192.168.0.2 \
  --pkg-url /root/kube1.18.0.tar.gz \
  --version v1.18.0
# 去除污点，允许 master 节点可以调度 pod
kubectl taint --overwrite=true node data-pipeline node-role.kubernetes.io/master=:PreferNoSchedule
data-pipeline 是机器的 node name，可以 kubectl get nodes 查看
kubectl taint nodes data-pipeline node-role.kubernetes.io/master:NoSchedule-
```

> 参数含义

| 参数名  | 含义                                             | 示例                    |
| ------- | ------------------------------------------------ | ----------------------- |
| passwd  | 服务器密码                                       | 123456                  |
| master  | k8s master节点IP地址、内网 ip                    | 192.168.0.2             |
| node    | k8s node节点IP地址、内网 ip                      | 192.168.0.3             |
| pkg-url | 离线资源包地址，支持下载到本地，或者一个远程地址 | /root/kube1.16.0.tar.gz |
| version | [资源包](http://store.lameleg.com)对应的版本     | v1.16.0                 |

## 安装 openfaas

- 拉取最新的部署仓库

  ```
  wget https://github.com/Byzanteam/deploy-data-pipeline/archive/master.zip
  unzip master.zip && cd deploy-data-pipeline-master
  ```

- kubectl apply -f namespaces.yml

- 修改 `hack/envs.conf`

- 由于 `openfaas` 和 `openfaas-fn` 两个空间的 `pod` 都会拉私有镜像，所以需要给两个空间都创建 `alihangzhou` `secret`

- ```
  kubectl create secret docker-registry alihangzhou --docker-server="registry.cn-hangzhou.aliyuncs.com" --docker-username="build-man@skylark" --docker-password="Q)i\$UIUxM9LumUo0" --docker-email="byzan@dev.com" -n openfaas && kubectl create secret docker-registry alihangzhou --docker-server="registry.cn-hangzhou.aliyuncs.com" --docker-username="build-man@skylark" --docker-password="Q)i\$UIUxM9LumUo0" --docker-email="byzan@dev.com" -n openfaas-fn
  ```

- ```
  make cp-config && make mk-dir && make replace-config
  ```

- ```shell
  kubectl apply -f secrets/postgres-dsn.yaml -n openfaas-fn && kubectl apply -f secrets/redis-config.yaml -n openfaas-fn
  ```

- ```shell
  kubectl apply -f postgres/. && kubectl apply -f redis/. && kubectl apply -f kafka/. && kubectl apply -f openfaas/.
  ```

- 安装 faas-cli

  - ```sh
    curl -sSL https://cli.openfaas.com | sudo sh
    ```

## 启动 skylark 相关 function

- 项目的代码都在[仓库](https://github.com/Byzanteam/openfaas-resource)，如果有任何不明白的，建议看每个 function 的 `handler` 函数

- deploy function

  ```
  cd functions 
  
  faas template pull https://github.com/openfaas-incubator/ruby-http
  faas template pull https://github.com/openfaas-incubator/python-flask-template
  faas template pull https://github.com/openfaas-incubator/golang-http-template
  
  faas-cli deploy -f skylark.yml
  ```

- 说明
  - buildtable
    - 基于 skylark-schema 信息用来建立表结构以及触发历史数据的导入
    - 输入参数是 topic 
  - skylark-form-by-page
    - 从 build table 触发信息中按页获取数据
  - skylark-schema
    - 获取 skylark 的信息
  - skylark-metadata
    - 获取在 gateway 层注册的 appid 等信息
  - write2postgres
    - 内置将数据写往 pg 的 function

## 拉取表单数据

- 上述的所有 function 都必须跑起来

- 往部署的平台上注册 skylark 表单信息

  - http://ip:port/v1/register

  - POST

  - ```
    {
      "metadata": {
        "app_id": "7a336a9171444fba5d3a1e5ae3e23c91d92bb68c6",
        "app_secret": "17c24c7d264cc50fc3ea2b9cfd79e8a484aaab986ca",
        "form": 464, // form id
        "namespace_id": 1,
        "url": "https://gxzh.cdht.gov.cn/api/v4/yaw/flows/" // v4 api
      }
    }
    ```

  - 记住返回来的 topic (endpoint) ，这个非常非常重要

  - 将 http://ip:port/v1/forwarder/topic 注册到对应 skylark 表单的 webhook 中，例如 `http://221.237.108.141:8082/v1/forwarder/e2d8eb96-69a4-4714-b56b-61c37d79c0bf`

- 部署表单的实时数据函数

  - 新建一个 aaa.yaml 文件

    ```yaml
    version: 1.0
    provider:
      name: openfaas
      gateway: http://127.0.0.1:31112
    functions:
      phone-realtime-ticket-summary: //自定义的名字
        lang: golang-http
        handler: ./skylarkform
        image: registry.cn-hangzhou.aliyuncs.com/byzanteam/skylark-form:v0.2
        build_args:
          GO111MODULE: on
        secrets:
          - alihangzhou
        environment:
          topic: "062c5e21-2f96-41e3-985d-f2ed5e109b5a" //基于实际情况填写
          gateway: "http://gateway.openfaas.svc.cluster.local:8080"
          write_debug: true
        annotations:
          topic: "062c5e21-2f96-41e3-985d-f2ed5e109b5a" //基于实际情况填写
    ```

  - faas-cli deploy -f aaa.yaml
    - up： build image、push image、deploy function

