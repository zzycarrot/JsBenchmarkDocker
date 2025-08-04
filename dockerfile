FROM node:18-bullseye

# 设置环境变量防止警告
ENV DEBIAN_FRONTEND=noninteractive
USER root
# 安装系统依赖（删除不必要的pacman命令）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    python3-pip  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 添加Adoptium仓库（提供OpenJDK二进制文件）
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - && \
    echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

# 安装JDK 17
RUN apt-get update && \
    apt-get install -y temurin-17-jdk && \
    java -version && \
    rm -rf /var/lib/apt/lists/*

# 设置JDK环境变量
ENV JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"


WORKDIR /ossf



COPY ossf-cve-benchmark/ .
COPY config.json .

RUN npm i 
RUN npm install css-loader@^6.0.0 --legacy-peer-deps  
RUN npm run-script build
RUN chmod -R +x /ossf
# 创建共享工具目录
RUN mkdir -p /ossf/analysis-tools

WORKDIR /
# 修复工具安装路径（使用绝对路径）
RUN ls -l /ossf/contrib/tools/nodejsscan/installers/install.sh
RUN sed -i 's/\r$//' /ossf/contrib/tools/nodejsscan/installers/install.sh && \  
    chmod +x /ossf/contrib/tools/nodejsscan/installers/install.sh && \  
    head -1 /ossf/contrib/tools/nodejsscan/installers/install.sh | grep -q '^#!' || \  
    sed -i '1i #!/bin/sh' /ossf/contrib/tools/eslint/installers/install.sh
RUN /ossf/contrib/tools/nodejsscan/installers/install.sh /ossf/analysis-tools/nodejsscan-dir

RUN ls -l /ossf/contrib/tools/eslint/installers/install.sh
RUN sed -i 's/\r$//' /ossf/contrib/tools/eslint/installers/install.sh && \  
    chmod +x /ossf/contrib/tools/eslint/installers/install.sh && \  
    head -1 /ossf/contrib/tools/eslint/installers/install.sh | grep -q '^#!' || \  
    sed -i '1i #!/bin/sh' /ossf/contrib/tools/eslint/installers/install.sh
RUN /ossf/contrib/tools/eslint/installers/install.sh /ossf/analysis-tools/eslint-dir

# RUN /ossf/contrib/tools/codeql/installers/install.sh /ossf/analysis-tools/codeql-dir
# RUN /ossf/contrib/tools/ideal-analysis/installers/install.sh /ossf/analysis-tools/ideal-analysis-dir
RUN chmod +x /ossf/analysis-tools
# 删除构建时运行的扫描命令（应作为运行时命令）
WORKDIR /ossf
RUN sed -i 's/\r$//' /ossf/bin/cli && \  
    chmod +x /ossf/bin/cli  
RUN sed -i 's/\r$//' /ossf/bin/cli.sh && \  
    chmod +x /ossf/bin/cli.sh
RUN chmod +x /tmp
RUN chmod +x /ossf/CVEs

RUN chmod -R 777 /tmp
RUN chmod -R 777 /ossf/CVEs  
EXPOSE 8080
ENTRYPOINT [ "/ossf/bin/cli.sh" ]

# CMD ["bin/cli.sh", "report", "--kind", "txt", "--tool", "eslint-default", "--tool", "codeql-default", "--tool", "ideal-analysis", "--tool", "nodejsscan-default", "*"]
