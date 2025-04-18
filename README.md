## TaskPyro 是什么？

TaskPyro 是一个轻量级的 Python 任务调度平台，专注于提供简单易用的任务管理和爬虫调度解决方案。它能够帮助您轻松管理和调度 Python 任务，特别适合需要定时执行的爬虫任务和数据处理任务。

![登录界面](https://www.helloimg.com/i/2025/03/06/67c8f0ad6c9a1.png)
![主界面](https://www.helloimg.com/i/2025/03/06/67c8f0adef1f7.png)

## 开发背景

在当今数字化时代，自动化数据采集和处理变得越来越重要。然而，现有的任务调度解决方案要么过于复杂，要么缺乏针对 Python 环境的特定优化。TaskPyro 正是为了解决这些痛点而诞生的，旨在为 Python 开发者提供一个简单、高效、可靠的任务调度平台。

## 为什么选择TaskPyro？

- 🚀 **轻量级设计**：占用资源小，运行高效
- 🔄 **灵活调度**：支持多种调度方式，满足各类需求
- 🐍 **Python环境管理**：自由分配不同的Python虚拟环境
- 📊 **可视化监控**：直观的任务运行状态展示
- 🔒 **安全可靠**：完善的异常处理和错误恢复机制


## 适用人群

TaskPyro 特别适合以下用户群体：

- 🔍 **数据工程师**：需要定期执行数据采集、清洗和处理任务
- 🕷️ **爬虫开发者**：需要管理和调度多个爬虫任务
- 📊 **数据分析师**：需要自动化数据分析流程
- 🛠️ **系统运维人员**：需要执行定时系统维护任务
- 🚀 **创业团队**：需要一个轻量级但功能完整的任务调度解决方案

## 使用流程
- 先配置Python环境
- 创建项目
- 创建定时任务

## 核心功能

TaskPyro 提供了一系列强大的功能，帮助您高效管理 Python 任务：

- 📅 **灵活的任务调度**
  - 支持 Cron 表达式定时调度
  - 支持固定间隔调度
  - 支持一次性任务执行
  - 支持任务依赖关系配置

- 🔧 **Python 环境管理**
  - 支持多个 Python 虚拟环境
  - 环境隔离，避免依赖冲突
  - 支持 pip 包管理

- 🕷️ **爬虫框架支持**
  - 支持 Scrapy 等主流爬虫框架
  - 支持 Selenium、Playwright、DrissionPage 等浏览器自动化工具
  - 提供完整的框架运行环境配置

- 📊 **任务监控与管理**
  - 实时任务状态监控
  - 详细的执行日志记录
  - 任务执行统计分析
  - 异常通知与告警

- 💼 **用户友好**
  - 直观的 Web 操作界面
  - 详细的使用文档
  - 简单的部署流程
  - 完善的错误处理机制


# Docker 安装

TaskPyro 提供了基于 Docker 的快速部署方案，让您能够轻松地在任何支持 Docker 的环境中运行。

## 前置条件

在开始安装之前，请确保您的系统已经安装了以下软件：

### Docker 安装

- Docker（本人使用的版本为 26.10.0，低于此版本安装可能会存在问题，建议删除旧版本，升级新版本docker）

### Docker Compose 安装

- Docker Compose（版本 2.0.0 或更高）
- 注意：如果您使用的是 Docker 26.1.0 版本，建议安装最新版本的 Docker Compose 以确保兼容性

## 安装步骤

### 0. 拉取代码

gitub
```bash
git clone https://github.com/taskPyroer/taskpyro.git
```

gitee

```bash
git clone https://gitee.com/taskPyroer/taskpyrodocker.git
```

> 可以直接拉取上面的代码，或者按下面的1、2、3步骤创建文件

### 1. 创建项目目录

```bash
mkdir taskpyro
cd taskpyro
```

### 2. 创建 docker-compose.yml 文件

在项目目录中创建 `docker-compose.yml` 文件，内容如下：

```yaml
version: '3'

services:
  frontend:
    image: crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-frontend:1.0
    ports:
      - "${FRONTEND_PORT:-7789}:${FRONTEND_PORT:-7789}"
    environment:
      - PORT=${FRONTEND_PORT:-7789}
      - SERVER_NAME=${SERVER_NAME:-localhost}
      - BACKEND_PORT=${BACKEND_PORT:-8000}
      - API_URL=http://${SERVER_NAME}:${BACKEND_PORT:-8000}
      - TZ=Asia/Shanghai
    env_file:
      - .env
    depends_on:
      - api

  api:
    image: crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-api:1.0
    ports:
      - "${BACKEND_PORT:-8000}:${BACKEND_PORT:-8000}"
    environment:
      - PORT=${BACKEND_PORT:-8000}
      - PYTHONPATH=/app
      - CORS_ORIGINS=http://localhost:${FRONTEND_PORT:-7789},http://127.0.0.1:${FRONTEND_PORT:-7789}
      - TZ=Asia/Shanghai
      - WORKERS=${WORKERS:-1}
    volumes:
      - /opt/taskpyrodata/static:/app/../static
      - /opt/taskpyrodata/logs:/app/../logs
      - /opt/taskpyrodata/data:/app/data
    env_file:
      - .env
    init: true
    restart: unless-stopped
```

### 3. 创建 .env 文件

在项目目录中创建 `.env` 文件，用于配置环境变量：

```env
FRONTEND_PORT=8080
BACKEND_PORT=9000
SERVER_NAME=localhost
WORKERS=1
```


### 4. 启动服务

```bash
docker-compose up -d
```
启动后直接在浏览器中访问至 http://<your_ip>:8080

## 安装注意事项

1. **数据持久化**
   - 数据文件会保存在 `/opt/taskpyrodata` 目录下，包含以下子目录：
     - `static`：静态资源文件
     - `logs`：系统日志文件
     - `data`：应用数据文件
   - 建议定期备份这些目录，特别是 `data` 目录

2. **环境变量配置**
   - 在 `.env` 文件中配置以下必要参数：
     - `FRONTEND_PORT`：前端服务端口（默认8080）
     - `BACKEND_PORT`：后端服务端口（默认9000）
     - `SERVER_NAME`：服务器域名或IP（默认localhost，不用修改）
     - `WORKERS`：后端工作进程数（默认1，不用修改）
     - 确保 `SERVER_NAME` 配置正确，否则可能导致API调用失败

3. **端口配置**
   - 前端服务默认使用8080端口
   - 后端服务默认使用9000端口
   - 确保这些端口未被其他服务占用
   - 如需修改端口，只需要更新 `.env` 文件中的配置

4. **容器资源配置**
   - 建议为容器预留足够的CPU和内存资源
   - 可通过Docker的资源限制参数进行调整
   - 监控容器资源使用情况，适时调整配置

## 常见问题

1. **前端服务无法访问**
   - 检查 `FRONTEND_PORT` 端口是否被占用
   - 确认前端容器是否正常启动：`docker-compose ps frontend`
   - 查看前端容器日志：`docker-compose logs frontend`
   - 验证 `SERVER_NAME` 配置是否正确

2. **后端API连接失败**
   - 检查 `BACKEND_PORT` 端口是否被占用
   - 确认后端容器是否正常启动：`docker-compose ps api`
   - 查看后端容器日志：`docker-compose logs api`
   - 验证 `CORS_ORIGINS` 配置是否包含前端访问地址

3. **容器启动失败**
   - 检查 Docker 服务状态：`systemctl status docker`
   - 确认 docker-compose.yml 文件格式正确
   - 验证环境变量配置是否完整
   - 检查数据目录权限：`ls -l /opt/taskpyrodata`

4. **数据持久化问题**
   - 确保 `/opt/taskpyrodata` 目录存在且有正确的权限
   - 检查磁盘空间是否充足
   - 定期清理日志文件避免空间占用过大
   - 建议配置日志轮转策略

5. **资源配置**
   - 根据实际需求调整 Docker 容器的资源限制
   - 监控服务器资源使用情况，适时调整配置


## 升级说明

要升级到新版本，请执行以下步骤：

```bash
# 拉取最新镜像
docker-compose pull

# 重启服务
docker-compose up -d
```

## 卸载说明

如果需要卸载 TaskPyro，可以执行以下命令：

```bash
# 停止并删除容器
docker-compose down

# 如果需要同时删除数据（谨慎操作！）
rm -rf /opt/taskpyrodata
```

# 系统资源监控

仪表盘提供了实时的系统资源使用情况监控，帮助您及时了解系统的运行状态。
![仪表盘界面](https://www.helloimg.com/i/2025/03/06/67c8f0adef1f7.png)
## CPU使用率

显示当前系统的CPU使用百分比，以及最近的CPU负载情况。
## 内存使用率

展示系统内存的使用情况，包括：
- 已使用内存/总内存
- 使用率百分比

例如：11.9 GB / 15.8 GB，使用率75.1%

## 磁盘使用率

监控系统磁盘存储空间的使用情况：
- 已使用空间/总空间
- 使用率百分比

例如：57.8 GB / 341.2 GB，使用率16.9%

# 任务执行统计

## 任务成功率

展示系统中任务的整体执行情况：
- 成功任务数/总任务数
- 成功率百分比

例如：16/18个任务成功，成功率89%

## 每日任务执行统计

通过图表形式展示每日任务执行的详细统计：
- 成功任务：显示绿色
- 失败任务：显示红色
- 错过任务：显示黄色

图表可以直观地展示任务执行的趋势和分布情况，帮助您更好地了解系统运行状况。

## 项目管理功能

TaskPyro 提供了直观的项目管理界面，支持添加和编辑项目。本文将详细介绍项目管理的各项功能。

## 查看项目列表

在项目管理界面，您可以查看已创建的项目列表。每个项目都包含以下信息：

![项目界面](https://www.helloimg.com/i/2025/03/06/67c8f2945051f.png)

## 添加/编辑项目

在项目管理界面，您可以通过点击"新建项目"按钮来创建新项目。新建项目界面如下：

![新建项目界面](https://www.helloimg.com/i/2025/03/06/67c8f2bff1156.png)

以下是各个字段的详细说明：

### 项目名称

- 为您的项目设置一个唯一的名称
- 建议包含版本信息，便于管理

### 工作路径

工作路径是项目文件的执行路径，系统会根据上传的ZIP文件结构自动推荐合适的工作路径：

- 单文件情况：如果ZIP解压后只有一个Python文件，工作路径默认设置为 `/`
- 文件夹情况：如果ZIP解压后包含项目文件夹（如 `Demo` 文件夹），且Python文件位于该文件夹中，则工作路径会设置为 `/Demo`

::: tip 提示
正确设置工作路径对项目的执行至关重要，它决定了Python文件的相对导入路径。
:::

### 项目描述

- 可以添加项目的详细说明
- 支持描述项目的功能、用途、注意事项等信息

### 项目标签

- 支持为项目添加多个标签
- 标签可用于项目分类和快速筛选
- 在输入框中输入标签名称，点击"添加"按钮即可创建新标签

### 项目文件上传

- 仅支持上传ZIP格式的压缩文件
- ZIP文件应包含完整的项目代码和相关资源
- 可以通过拖拽或点击选择文件的方式上传

::: warning 注意
请确保ZIP文件的组织结构合理，便于系统正确识别工作路径。
:::

## 使用建议

1. 项目命名建议包含版本信息，便于版本管理
2. 合理使用标签系统，便于项目分类和检索
3. 在上传ZIP文件前，建议检查项目结构的合理性
4. 确保工作路径设置正确，避免执行时出现导入错误

# Python虚拟环境管理

TaskPyro提供了强大而灵活的Python虚拟环境管理功能，默认支持Python 3.9.21版本。通过直观的Web界面，您可以轻松创建、编辑和管理虚拟环境，为您的任务提供独立的运行环境。

## 核心特性

### 1. 环境复用与管理

- 🔄 **一对多关系**：一个虚拟环境可以同时服务于多个定时任务，提高资源利用效率
- ⚙️ **灵活配置**：支持自定义环境名称和依赖包，满足不同任务的需求

### 2. 实时安装日志

- 📝 **详细记录**：完整记录包安装过程，包括下载进度、依赖解析等信息
- 🔍 **错误追踪**：清晰显示安装过程中的警告和错误信息，便于问题排查
- ⚡ **实时反馈**：安装过程实时展示，无需等待即可了解安装状态

### 3. 镜像源管理

- 🌐 **多源支持**：内置多个常用PyPI镜像源，包括：
  - 官方PyPI源
  - 阿里云镜像源
  - 清华大学镜像源
  - 中国科技大学镜像源
  - 华为云镜像源
  - 腾讯云镜像源
- ✏️ **自定义配置**：支持添加、编辑和删除镜像源
- 🔄 **灵活切换**：可随时切换到最适合的镜像源，优化包下载速度

## 相比使用Docker创建定时任务的优势

### 1. 资源效率

- 🚀 **更低的资源占用**：无需为每个任务创建独立容器，显著减少系统资源消耗
- 💾 **更少的磁盘空间**：环境复用避免重复安装相同的依赖包
- ⚡ **更快的启动速度**：直接使用虚拟环境，无需等待容器启动

### 2. 管理便捷

- 🎯 **集中管理**：统一的Web界面管理所有虚拟环境
- 🔄 **即时生效**：环境更新后立即生效，无需重建容器
- 📊 **资源监控**：直观展示环境使用情况和任务关联关系

### 3. 灵活性

- 🔗 **环境共享**：多个任务可共享同一个虚拟环境
- 🛠️ **快速调整**：随时添加或移除依赖包，无需重新构建镜像
- 🔍 **便于调试**：直接访问虚拟环境，简化问题排查流程

## 使用建议

1. 根据项目依赖合理规划虚拟环境，相似依赖的任务可以共用同一环境
2. 定期检查和更新依赖包，确保安全性和稳定性
3. 选择地理位置较近的镜像源，提升包下载速度
4. 保留关键依赖包的版本号，避免版本更新导致的兼容性问题

## 界面展示
### 入口界面
![入口界面](https://www.helloimg.com/i/2025/03/06/67c8f2c0f18a5.png)

### 新建环境
![新建环境](https://www.helloimg.com/i/2025/03/06/67c8f2c020759.png)

### 安装日志
![安装日志](https://www.helloimg.com/i/2025/03/06/67c8f2c09fdd6.png)

### 镜像源管理
![镜像源管理](https://www.helloimg.com/i/2025/03/06/67c8f2c09a765.png)

# 任务管理

TaskPyro提供了强大而灵活的任务管理功能，让您能够轻松创建和管理Python脚本的定时任务。

## 创建任务

在TaskPyro中创建新任务时，您可以：

1. 为任务指定一个描述性的名称
2. 选择已创建的项目和对应的Python虚拟环境
3. 设置要执行的Python脚本命令（例如：`python script.py`）
4. 配置任务的调度方式

![新建任务界面](https://www.helloimg.com/i/2025/03/06/67c8f2eb516fd.png)

## 调度类型

TaskPyro支持多种调度类型，以满足不同的任务执行需求：

### 间隔执行

按照固定的时间间隔重复执行任务。您可以设置：
- 间隔时长（支持秒、分钟、小时、天等单位）
- 首次执行时间

### 一次性执行

在指定的日期和时间执行一次任务。

### Cron表达式

使用标准的Cron表达式来定义复杂的执行计划，支持：
- 分钟级别的精确控制
- 每天、每周、每月的定时执行
- 复杂的组合调度规则

## 任务列表

TaskPyro的主界面提供了丰富的任务调度信息和操作功能：

### 基本信息
- 任务名称和描述
- 所属项目和Python虚拟环境
- 执行命令和参数
- 下次执行时间
- 任务状态（活跃中、暂停、错误）

### 任务操作
- 暂停/启动调度任务
- 强制终止正在运行的任务实例
- 编辑任务配置
- 添加/编辑任务标签，方便分类管理

![任务列表界面](https://www.helloimg.com/i/2025/03/06/67c8f2ec0adeb.png)

## 执行历史

每个任务都有详细的执行历史记录，您可以查看：

- 历次执行的开始和结束时间
- 任务执行状态（成功/失败）
- 执行耗时统计
- 错误信息（如果执行失败）

![执行历史界面](https://www.helloimg.com/i/2025/03/06/67c8f2eb6f17c.png)

## 运行日志

TaskPyro提供了强大的日志查看功能：

### 日志筛选
- 按时间范围筛选
- 支持关键词搜索
- 按日志级别过滤（INFO、ERROR等）

### 实时查看
- 自动刷新最新日志
- 支持暂停自动刷新
- 可查看历史日志记录

![运行日志界面](https://www.helloimg.com/i/2025/03/06/67c8f2ebdfdbc.png)

## 并发实例管理

TaskPyro提供了灵活的并发实例管理功能：

1. 默认情况下，如果上一个任务实例还在运行，新的调度时间到达时将跳过执行
2. 通过设置最大并发实例数，可以允许同一个任务的多个实例同时运行
3. 适用场景示例：
   - 任务执行时间为1分钟
   - 调度间隔为30秒
   - 设置并发实例后，新的任务实例将在下一个时间点启动，不需要等待上一个实例完成
   - 不设置并发实例时，将等待上一个实例完成后，在下一个调度点执行

## 任务编辑

您可以随时编辑已创建的任务：
- 修改任务名称和描述
- 更新Python环境配置
- 调整调度设置
- 启用/禁用并发实例
- 管理任务标签

通过这些功能，TaskPyro为您提供了一个完整的Python任务调度解决方案，帮助您高效管理自动化任务。

# 设置

## 用户设置

在用户设置页面，您可以管理您的账户设置并修改密码。系统默认的管理员账户信息如下：

- 用户名：admin
- 默认密码：admin123

为了系统安全，建议您在首次登录后立即修改默认密码。修改密码时，需要输入当前密码和新密码，并确认新密码。

## 许可证设置

许可证设置页面显示了您当前的许可证状态和使用限制。免费版用户可以使用以下功能：

- 创建最多 5 个定时任务
- 创建最多 2 个项目
- 创建最多 2 个虚拟环境

如需突破以上限制，您可以[购买许可证]以获得无限制使用权限。点击"激活"按钮，输入有效的许可证密钥即可激活高级功能。如需购买许可证，请订阅。

## 邮件设置

邮件设置功能允许您配置系统的邮件通知功能。当启用邮件通知后，系统会在定时任务执行出错时自动发送警报邮件。

配置邮件通知需要设置以下信息：

1. SMTP服务器地址
2. SMTP端口
3. 邮箱用户名
4. 邮箱密码
5. 启用通知
完成上面配置后，点击保存按钮即可。

配置完成后，添加收件人邮箱地址，您可以点击"测试邮件"

# 订阅方案

## 免费版

免费版本为您提供以下功能限制：

- 创建最多 5 个定时任务
- 创建最多 2 个项目
- 创建最多 2 个虚拟环境

## 付费许可证

购买许可证后，您可以享受无限制的功能：

- 无限制创建定时任务
- 无限制创建项目
- 无限制创建虚拟环境

::: tip 重要提示
在授权有效期内，您可以享受完全无限制的功能，并且支持更换绑定的服务器。
:::

## 价格方案

我们提供多种灵活的付费方案，满足您不同的需求：

- 半年付：66元/6个月
- 年付：99元/年

## 购买方式

请添加微信：**PJ221BBB**

::: tip 备注说明
加好友时请备注：taskpyro
:::

## 价格调整说明

随着产品功能的不断完善和升级，价格可能会进行相应调整。建议您及时关注最新的价格信息。

# 学习交流

| 微信：PJ221BBB | 公众号：布鲁的Python之旅 |
|-------------|-----------------|
| ![个人微信](https://www.helloimg.com/i/2025/03/06/67c8f41cc017f.png) | ![公众号](https://www.helloimg.com/i/2025/03/06/67c8f41ca7f2a.png) |
