# GitLab-ee(Locally)

### Install(docker compose)

ce 與 ee 差異基本一樣但是建議安裝ee因為沒付費等於ce只要付錢就可以變成ee
https://hsunstudio.notion.site/GitLab-ee-Locally-1cec8d49edb64a078aa1c1a13046e657?pvs=4(notion 縮減版)
```yaml
version: '3.6'
services:
  gitlab:
    image: 'gitlab/gitlab-ee:latest'
    container_name: gitlab
    restart: always
    hostname: 'tomoffice.duckdns.org'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://tomoffice.duckdns.org:5100' #external_url 'http://192.168.10.100:5100
        gitlab_rails['gitlab_shell_ssh_port'] = 22
    ports:
      - '5100:5100'
      - '443:443'
      - '22:22'
    volumes:
      - config:/etc/gitlab
      - logs:/var/log/gitlab
      - data:/var/opt/gitlab
    shm_size: '256m'

  gitlab-runner:  
    image: 'gitlab/gitlab-runner:latest'
    container_name: gitlab-runner
    restart: always
    volumes:
      - gitlab_runner_config:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  config:
  logs:
  data:
  gitlab_runner_config:
```

runner可以在client裝也可以在server裝,只要註冊到gitlab server就可以用,如果server算力不夠可以選擇在自己電腦裝

### 改善版本(打開container registry)

```yaml
version: '3.6'
services:
  gitlab:
    image: 'gitlab/gitlab-ee:latest'
    container_name: gitlab
    restart: always
    hostname: 'tomoffice.duckdns.org'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://192.168.10.100:5100'
        gitlab_rails['gitlab_shell_ssh_port'] = 22
        gitlab_rails['registry_enabled'] = true
        gitlab_rails['registry_host'] = "192.168.10.100"
        gitlab_rails['registry_port'] = "5005"
        gitlab_rails['registry_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"
        registry_external_url 'http://192.168.10.100:5005'
    ports:
      - '5100:5100'
      - '443:443'
      - '22:22'
      - "5005:5005"
    volumes:
      - config:/etc/gitlab
      - logs:/var/log/gitlab
      - data:/var/opt/gitlab
    shm_size: '256m'

  gitlab-runner:
    image: 'gitlab/gitlab-runner:latest'
    container_name: gitlab-runner
    restart: always
    volumes:
      - gitlab_runner_config:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  config:
  logs:
  data:
  gitlab_runner_config:
```

服務起來後沒辦法登入

因為沒有密碼

必須要去container裡面找所以docekr ps 找gitlab找到後

grep 'Password' /etc/gitlab/initial_root_password

拿到password後就用root登入

登入去改一下密碼 想辦法到Admin通常在左邊→User→更改密碼

[https://docs.gitlab.com/ee/install/docker.html](https://docs.gitlab.com/ee/install/docker.html)

[https://www.atlantic.net/dedicated-server-hosting/how-to-install-gitlab-with-docker-and-docker-compose-on-arch-linux/](https://www.atlantic.net/dedicated-server-hosting/how-to-install-gitlab-with-docker-and-docker-compose-on-arch-linux/)

### CI CD | 自架沒有TLS

![https://docs.gitlab.com/ee/ci/introduction/img/gitlab_workflow_example_11_9.png](https://docs.gitlab.com/ee/ci/introduction/img/gitlab_workflow_example_11_9.png)

gitlab流程：

git push gitlab → AutoDevOps偵測到變動 → Gitlab Runner安排.gitlab-ci.yml裡面的任務 → 結束

Client流程：

啟動Service(gitlab + runner) → 進入gitlab-runner 註冊 gitlab server → 檢查server有沒有runner → 在project新增.gitlab-ci.yml(記得打runner tag) → 新增或修改project

### container registry | gitlab的****Locally Docker Registry(可選)****

新增/etc/gitlab/gitlab.rb

```go
gitlab_rails['registry_enabled'] = true
gitlab_rails['registry_host'] = "192.168.10.100"  # 你的註冊庫域名
gitlab_rails['registry_port'] = "5005"  # 你想要用於註冊庫的端口
gitlab_rails['registry_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"  # 存儲 Docker 鏡像的路徑
registry_external_url 'http://192.168.10.100:5005'

sudo gitlab-ctl reconfigure
```

或者在docker compose 新增

```yaml
environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://192.168.10.100:5100'
        gitlab_rails['gitlab_shell_ssh_port'] = 22
        gitlab_rails['registry_enabled'] = true
        gitlab_rails['registry_host'] = "192.168.10.100"
        gitlab_rails['registry_port'] = "5005"
        gitlab_rails['registry_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"
        registry_external_url 'http://192.168.10.100:5005'

environment:
  - GITLAB_EXTERNAL_URL=http://192.168.10.100:5100
  - GITLAB_SHELL_SSH_PORT=22
  - GITLAB_REGISTRY_ENABLED=true
  - GITLAB_REGISTRY_HOST=192.168.10.100
  - GITLAB_REGISTRY_PORT=5005
  - GITLAB_REGISTRY_PATH=/var/opt/gitlab/gitlab-rails/shared/registry
  - GITLAB_REGISTRY_EXTERNAL_URL=http://192.168.10.100:5005
```

### Gitlab runner(公用) | 讓 gitlab有執行程式的能力

### 註冊ruuner到server：

```bash
docker run -d --name gitlab-runner --restart always \
-v gitlab_runner:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest

docker exec -it gitlab-runner bash

gitlab-runner register #註冊runner

gitlab-runner list #檢查註冊的runner

gitlab-runner verify --delete -t YMsSCHnjGssdmz1JRoxx -u http://xxxxxxxx

gitlab-runner verify --delete #刪除註冊的runner
```

```bash
gitlab-runner register \
--non-interactive \
--executor="docker" \
--docker-image docker:latest \
--url "http://gitlab:5100" \
--registration-token "mpGW_MANEEmUW-Yo63yh" \
--description "Default Runner" \
--tag-list "Dind" \
--run-untagged="true" \
--docker-privileged \ <-dind模式要開啟
--locked="false";

原廠操作說明：https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-in-docker
```
先找到token等一下gitlab-runner register會需要用到

1. 需要填入gitlab server的網址
2. 把剛剛的token數入進去
3. 隨便打描述而已 | Default Runner
4. tag很重要因為gitlab-ci.yml會去找相應的tag去執行ci | Default,Alpine
5. optional所以沒打
6. 選擇執行器 | docker
    1. **virtualbox**: 此執行器允許你在 VirtualBox 虛擬機中運行工作。它會為每個新的建置工作創建一個新的虛擬機。
    2. **docker**: 是其中一個最受歡迎的執行器，它允許你在 Docker 容器中運行建置和測試工作。每項工作都會在一個新的容器中執行，確保了環境的清潔和隔離。
    3. **docker-autoscaler**: 這是 Docker 執行器的一個特殊版本，它可以根據需求自動調整 GitLab Runner 的實例數量。
    4. **instance**: 此執行器用於 GitLab 的 Kubernetes 整合。它基於 Google Compute Engine 的實例。
    5. **kubernetes**: 允許在 Kubernetes 叢集上運行工作。每項工作都會在一個新的 pod 中運行。
    6. **shell**: 直接在所選的機器上運行工作，不需要任何容器或虛擬化技術。這需要機器的環境是清潔和安全的。
    7. **ssh**: 此執行器會 SSH 連接到一個遠程機器，然後在該機器上運行指令，就像在 shell 執行器上一樣。
    8. **docker+machine**: 使用 Docker Machine 來創建、啟動、停止或刪除 Docker 主機。這意味著它可以自動為你的建置工作創建新的虛擬機。
    9. **custom**: 允許你定義自己的執行器，與 GitLab Runner API 互動。
    10. **docker-windows**: 是 Docker 執行器的一個變體，專為 Windows 環境而設計。
    11. **parallels**: 使用 Parallels Desktop 虛擬機來運行工作。
7. 輸入初始映像檔 | docker:latest


這時候就在gitlab加入了一個runner


反正就是想辦法弄出.gitlab-ci.yml


因為當初在設定runner的時候是使用alpine所以並不是golang:alpine所以必須要安裝golang


這時候build就完成了


因為在寫unit test的時候把固定路徑寫上去了所以測試會失敗


將測試ip寫成硬編碼192.168.10.202通過測試


通過測試的細節

### DinD runner  | 像是container裡面再裝一個docker 開啟ubuntu container

```bash
gitlab-runner register \
--non-interactive \
--executor="docker" \
--docker-image ubuntu:latest \
--url "http://gitlab:5100" \
--registration-token "mpGW_MANEEmUW-Yo63yh" \
--description "Default Runner" \
--tag-list "Dind" \
--run-untagged="true" \
--docker-privileged \
--locked="false";

原廠操作說明：https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-in-docker
```

.gitlab-ci.yml

```bash
image: docker:latest

services:
  - name: docker:dind #為了讓daemon可以使用
    command: ["--insecure-registry=192.168.10.100:5005"]
stages:
  - build
  - test
  - deploy
variables:
  GO111MODULE: "on"
  DOCKER_HOST: tcp://docker:2375 #官方關閉TLS #指示runner使用docker:dind的daemon
  DOCKER_TLS_CERTDIR: "" #官方關閉TLS
  DOCKER_DRIVER: overlay2

before_script:
  - apk add --no-cache go
  - go version
	# 預先下載所有依賴關係
  - go mod download  
  # 登錄 GitLab Container Registry
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
build:
  stage: build
  script:
    - docker build --platform linux/arm64 -t "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" .
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
  tags:
    - Default
  only:
    - chipM2 #這裡我改了一個macos能跑的版本原本是amd64的image
						 #同時遇到了ubuntu與alpine之間的clib 與 glib的差異

test:
  stage: test
  variables:
    SERVER: 192.168.10.102
  script:
    #- docker run -e SERVER=192.168.10.102 "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" go test -v ./...
    - go test -v ./...
  tags:
    - Default
  only:
    - chipM2

deploy:
  stage: deploy
  script:
    - docker pull "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
    - docker tag "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" tomoffice/rabbitmq:arm64
    - echo "$DOCKERHUB_PASSWORD" | docker login -u $DOCKERHUB_USERNAME --password-stdin
    - docker push tomoffice/rabbitmq:arm64
    - docker logout
  tags:
    - Default
  only:
    - chipM2
```

dockerfile

```bash

FROM arm64v8/golang:latest AS builder


WORKDIR /rabbitmq


COPY . /rabbitmq/


RUN go mod download

WORKDIR /rabbitmq/consumer/
#RUN go build -o rabbitmqConsumer main.go 
#RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o rabbitmqConsumer .
RUN GOOS=linux GOARCH=arm64 go build -o rabbitmqConsumer .


FROM arm64v8/ubuntu:latest


WORKDIR /exec


COPY --from=builder /rabbitmq/consumer/rabbitmqConsumer .


CMD ["./rabbitmqConsumer"]
```

### 開啟特權模式｜build錯誤看到no such host

1.修改 /etc/gitlab-runner/config.toml 

應該不會想用這個方法因為gitlab-runner 沒有vi,vim,nano……

```yaml
concurrent = 1                            
check_interval = 0                        
shutdown_timeout = 0                      
                                          
[session_server]                          
  session_timeout = 1800                  
                                          
[[runners]]                               
  name = "Default Runner"                 
  url = "http://gitlab:5100"              
  id = 4                                  
  token = "9jR6i-h7k5Tx2SXBNezk"          
  token_obtained_at = 2023-08-10T09:53:21Z
  token_expires_at = 0001-01-01T00:00:00Z 
  executor = "docker"                     
  [runners.cache]
    MaxUploadedArchiveSize = 0
  [runners.docker]
    tls_verify = false
    image = "ubuntu:latest"
    privileged = false <-這裡改成true 
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
```

2.註冊的時候就開啟

```bash
gitlab-runner register \
--non-interactive \
--executor="docker" \
--docker-image ubuntu:latest \
--url "http://gitlab:5100" \
--registration-token "mpGW_MANEEmUW-Yo63yh" \
--description "Default Runner" \
--tag-list "Default,Ubuntu" \
--run-untagged="true" \
--docker-privileged \
--locked="false";

原廠操作說明：https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-in-docker
```

### 關閉TLS(如果對container registry操作失敗)


在.gitlab-ci.yml底下修改runner行為

```bash
default:
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  before_script:
    - docker info

variables:
  # When using dind service, you must instruct docker to talk with the
  # daemon started inside of the service. The daemon is available with
  # a network connection instead of the default /var/run/docker.sock socket.
  #
  # The 'docker' hostname is the alias of the service container as described at
  # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services
  #
  # If you're using GitLab Runner 12.7 or earlier with the Kubernetes executor and Kubernetes 1.6 or earlier,
  # the variable must be set to tcp://localhost:2375 because of how the
  # Kubernetes executor connects services to the job container
  # DOCKER_HOST: tcp://localhost:2375
  #
  DOCKER_HOST: tcp://docker:2375 <-添加
  #
  # This instructs Docker not to start over TLS.
  DOCKER_TLS_CERTDIR: "" <-添加

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests

原廠DinD關閉TLS [https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker-in-docker-with-tls-disabled-in-the-docker-executor](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker-in-docker-with-tls-disabled-in-the-docker-executor)
```


### 奇怪問題: dind裡面的insecure registry

看起來就是dind裡面也有dockerDaemon而如果要接上沒有https的registry本來在dockerr就要設定insecure registry,所以在docker裡面的docker也需要設定

有人也有一樣的問題：[https://stackoverflow.com/questions/50133073/gitlab-ci-docker-in-docker-access-to-insecure-registry](https://stackoverflow.com/questions/50133073/gitlab-ci-docker-in-docker-access-to-insecure-registry)

[https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#troubleshooting](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#troubleshooting)

### **Docker Socket Binding runner | 與runner在同一個平面的container**

docker socket binding

```bash
gitlab-runner register \
--non-interactive \
--executor="docker" \
--docker-image docker:latest \
--url "http://gitlab:5100" \
--registration-token "mpGW_MANEEmUW-Yo63yh" \
--description "Socket Runner" \
--tag-list "Socket" \
--run-untagged="true" \
--docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
--locked="false";

/etc/gitlab-runner/config.toml
[[runners]]
  name = "Socket Runner"
  url = "http://gitlab:5100"
  id = 5
  token = "oL8pCA1zJszuzJXTPUXh"
  token_obtained_at = 2023-08-10T17:20:04Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker"
  [runners.cache]
    MaxUploadedArchiveSize = 0
  [runners.docker]
    tls_verify = false
    image = "ubuntu:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
    shm_size = 0

原廠socket綁定：https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-socket-binding
```

既然不是Docker in Docker 代表當job送出去後會在宿主裡面產生一個container等同於與gitlab container在同一個平面

Socket binding可以跨stage使用產生的檔案

.gitlab-ci.yml

```bash
image: docker:latest

stages:
  - build
  - test
  - deploy
variables:
  GO111MODULE: "on"
  DOCKER_HOST: unix:///var/run/docker.sock 
	#指示 Runner 使用宿主機上的 Docker daemon。
	#這稱為 "Docker Socket Binding" 或 "Docker Outside of Docker"（DooD）模式。
  DOCKER_TLS_CERTDIR: "" #官方關閉TLS

before_script:
  - docker info
  - apk add --no-cache go
  - go version
  - go mod download  # 預先下載所有依賴關係
  # 登錄 GitLab Container Registry
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
build:
  stage: build
  script:
    - docker build --platform linux/arm64 -t "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" .
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
  tags:
    - Socket
  only:
    - uploader

test:
  stage: test
  variables:
    SERVER: 192.168.10.102
  script:
    #- docker run -e SERVER=192.168.10.102 "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" go test -v ./...
    - go test -v ./...
  tags:
    - Socket
  only:
    - uploader

deploy:
  stage: deploy
  script:
    - docker pull "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
    - docker tag "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" tomoffice/rabbitmq:arm64
    - echo "$DOCKERHUB_PASSWORD" | docker login -u $DOCKERHUB_USERNAME --password-stdin
    - docker push tomoffice/rabbitmq:arm64
    - docker logout
  tags:
    - Socket
  only:
    - uploader
```

### DinD 與 Socket Binding 比較

![solution-3.png](https://www.tiuweehan.com/img/solution-1.png)

![docker-components.png](https://www.tiuweehan.com/img/docker-components.png)

DinD結構

```bash
宿主
└── Docker 守護程序
  ├── CI Runner 容器 (Docker 客戶端)
  │   └── Docker 守護程序 (在 Runner 容器內)
  │       └── 被runner構建的容器 (例如 docker build -t xxx .)
  └── 其他容器 (例如 gitlab)
```

Docker Socket Mounting

```bash
宿主
└── Docker 守護程序
  ├── CI Runner 容器 (透過掛載的 socket 與 Docker 守護程序通訊)
  ├── 被runner構建的容器 (例如 docker build -t xxx .)
  └── 其他容器 (例如 gitlab)
```

## 速度

DinD與Socket Binding執行一樣的script結果

DinD
00:06:20
Socket Binding
00:04:37

## Runner

DinD

Socket Binding

```bash
gitlab-runner register \
--non-interactive \
--executor="docker" \
--docker-image ubuntu:latest \
--url "http://gitlab:5100" \
--registration-token "mpGW_MANEEmUW-Yo63yh" \
--description "Default Runner" \
--tag-list "Dind" \
--run-untagged="true" \
--docker-privileged \
--locked="false";
```

```bash
gitlab-runner register \
--non-interactive \
--executor="docker" \
--docker-image docker:latest \
--url "http://gitlab:5100" \
--registration-token "mpGW_MANEEmUW-Yo63yh" \
--description "Socket Runner" \
--tag-list "Socket" \
--run-untagged="true" \
--docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
--locked="false";
```

## .gitlab-ci.yml

DinD

```yaml
image: docker:latest

services:
  - name: docker:dind
    command: ["--insecure-registry=192.168.10.100:5005"]
stages:
  - build
  - test
  - deploy

variables:
  GO111MODULE: "on"
  DOCKER_HOST: tcp://docker:2375
  DOCKER_TLS_CERTDIR: ""
  DOCKER_DRIVER: overlay2

before_script:
  - apk add --no-cache go
  - go version
  - go mod download
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
build:
  stage: build
  script:
  tags:
    - Dind
  only:
    - chipM2

test:
  stage: test
  variables:
    SERVER: 192.168.10.102
  script:
  tags:
    - Dind
  only:
    - chipM2

deploy:
  stage: deploy
  script:
  tags:
    - Dind
  only:
    - chipM2
```

每一個stage都是不同的區域

例如 在build stage裡面使用docker build 出來的image不能拿到test 與 deploy用

Socket Binding

```yaml
image: docker:latest

stages:
  - build
  - test
  - deploy

variables:
  GO111MODULE: "on"
  DOCKER_HOST: unix:///var/run/docker.sock
  DOCKER_TLS_CERTDIR: ""

before_script:
  - docker info
  - apk add --no-cache go
  - go version
  - go mod download  
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
build:
  stage: build
  script:
  tags:
    - Socket
  only:
    - uploader

test:
  stage: test
  variables:
    SERVER: 192.168.10.102
  script:
  tags:
    - Socket
  only:
    - uploader

deploy:
  stage: deploy
  script:
  tags:
    - Socket
  only:
    - uploader
```

整個都是一個container所以檔案可以在不同的stage存取

### 參考：

原廠DinD操作：[https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-in-docker](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker-in-docker-with-tls-disabled-in-the-docker-executor) (dind 要注意 runner呼叫的container的docker daemon 也要使用insecure registry原廠沒寫)

原廠Socket Binding操作：[https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-socket-binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-socket-binding) (原廠沒寫在Socket Binding的模式.gitlab-ci.yml host要指向哪裡)
