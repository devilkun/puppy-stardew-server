<div align="center">

<table>
<tr>
<td width="30%" align="center">
  <img src="logo.png" alt="Puppy Stardew Server Logo" width="200"/>
</td>
<td width="70%">

# Puppy Stardew Server
## 星露谷物语一键搭建开服联机

[![Docker Pulls](https://img.shields.io/docker/pulls/truemanlive/puppy-stardew-server)](https://hub.docker.com/r/truemanlive/puppy-stardew-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/truemanlive/puppy-stardew-server)](https://hub.docker.com/r/truemanlive/puppy-stardew-server)
[![GitHub Stars](https://img.shields.io/github/stars/truman-world/puppy-stardew-server)](https://github.com/truman-world/puppy-stardew-server)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[English](README.md) | 中文

**一键部署星露谷物语服务器 | 全平台联机支持**

</td>
</tr>
</table>

</div>

---

## 项目架构

```mermaid
graph TB
    subgraph "客户端层"
        PC[PC玩家]
        Mobile[iOS/Android玩家]
        Console[主机玩家]
    end

    subgraph "网络层"
        FW[防火墙<br/>端口 24642/UDP]
        VNC[VNC访问<br/>端口 5900/TCP]
    end

    subgraph "Docker容器"
        Entry[启动脚本]
        Steam[SteamCMD<br/>游戏下载器]
        SMAPI[SMAPI 4.3.2<br/>模组加载器]

        subgraph "游戏模组"
            AHH[AutoHideHost v1.2.2<br/>即时睡眠 + 隐藏房主]
            AOS[Always On Server v1.20.3<br/>24/7自动化]
            SAL[ServerAutoLoad v1.2.1<br/>自动加载存档]
            SLG[Skill Level Guard v1.4.0<br/>技能等级保护]
        end

        Game[星露谷物语 1.6.15<br/>游戏服务器]
    end

    subgraph "数据持久化"
        Saves[(存档文件)]
        Config[(模组配置)]
        SteamData[(Steam缓存)]
    end

    PC --> FW
    Mobile --> FW
    Console --> FW
    FW --> Game

    VNC -.-> Entry
    Entry --> Steam
    Steam --> SMAPI
    SMAPI --> AHH
    SMAPI --> AOS
    SMAPI --> SAL
    SMAPI --> SLG
    AHH --> Game
    AOS --> Game
    SAL --> Game
    SLG --> Game

    Game -.-> Saves
    Game -.-> Config
    Steam -.-> SteamData

    style AHH fill:#90EE90
    style Game fill:#FFD700
    style SMAPI fill:#87CEEB
    style SLG fill:#FFA500
```

## 3分钟搭建星露谷物语服务器

搭建**星露谷物语专用服务器**从未如此简单！通过**一条命令**，您就可以拥有自己的 24/7 多人联机服务器，支持**全平台**联机 - PC、Mac、Linux、iOS 和 Android 玩家都可以一起游戏。

**完美适用于：**
- **远程联机** - 与世界各地的朋友一起玩
- **跨平台游戏** - iOS、Android 和 PC 玩家一起联机
- **24/7 在线服务器** - 随时加入，无需房主在线
- **简单搭建** - 使用 Docker Compose 一键部署
- **低资源占用** - 仅需 2GB 内存即可流畅运行

## 核心功能

- **一键部署** - 一条命令 3 分钟完成部署
- **全平台支持** - PC、Mac、Linux、iOS、Android 全支持
- **24/7 专用服务器** ⚡ - 服务器独立运行，不需要房主在线
- **Docker Compose** - 轻松部署和管理
- **资源高效** - 2GB 内存服务器也能流畅运行
- **自动加载存档** - 重启容器，存档自动加载
- **VNC 远程访问** 🖥️ - 内置 VNC，首次设置超简单
- **即时睡眠** - 附加功能：玩家随时可以睡觉，无需等待
- **隐藏房主** - 房主玩家自动隐藏，零干扰
- **技能等级保护** 🛡️ - 新功能：防止等级异常，保持自然成长

<div align="center">

![即时睡眠演示](https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/screenshots/game/instant-sleep-demo.gif)

*附加功能：即时睡眠 - 点击床 → 立即睡眠 → 新的一天开始！*

</div>

## 最新版本更新

### v1.0.58 (2025年11月9日)

**Skill Level Guard v1.4.0 - 重大修复：**
- **✅ 已修复：** Always On Server 容器重启后自动启用功能正常工作
- **新增：** 通过反射调用ToggleAutoMode方法实现Auto Mode自动启用
- **验证：** 游戏在无玩家时正确暂停，ServerAutoLoad自动加载存档
- **保持：** 技能等级防护功能继续工作，基于经验值精确计算等级

**核心改进：**
- 完全自动化的Always On Server启用流程
- 无需手动按F9或VNC操作
- 容器重启后游戏自动暂停，等待玩家连接

## 快速开始

### 观看一键部署演示

[![asciicast](https://asciinema.org/a/SYBS2qWsb5ZlSolbFPuoA7EJY.svg)](https://asciinema.org/a/SYBS2qWsb5ZlSolbFPuoA7EJY)

### 方式 1：一键部署（推荐小白使用）

**中文版:**

```bash
curl -sSL https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/quick-start-zh.sh | bash
```

脚本会自动：
- 检查 Docker 安装
- 引导输入 Steam 凭证
- 创建必要目录并设置正确权限
- 生成配置文件
- 启动服务器
- 显示连接信息

**就这么简单！** ☕ 下载游戏文件时去喝杯咖啡（约 1.5GB）。

<details>
<summary><h3>方式 2：手动部署（进阶用户）</h3></summary>

#### 前置要求

- 已安装 Docker 和 Docker Compose
  - **快速安装**（Linux）：`curl -fsSL https://get.docker.com | sh`
  - **或参考官方指南**：[安装 Docker](https://docs.docker.com/get-docker/)
- 一个 Steam 账户，**并且已购买星露谷物语**
- 最低 2GB 内存，推荐 4GB
- 2GB 可用磁盘空间

#### 步骤 1：下载配置文件

```bash
# 克隆仓库
git clone https://github.com/truman-world/puppy-stardew-server.git
cd puppy-stardew-server

# 或者直接下载文件
mkdir puppy-stardew && cd puppy-stardew
wget https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/docker-compose.yml
wget https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/.env.example
```

#### 步骤 2：配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑并填写您的 Steam 凭证
nano .env  # 或使用您喜欢的编辑器
```

**`.env` 示例：**
```env
STEAM_USERNAME=your_steam_username
STEAM_PASSWORD=your_steam_password
ENABLE_VNC=true
VNC_PASSWORD=stardew123
```

**重要**：您必须在 Steam 上拥有星露谷物语。游戏文件通过您的账户下载。

#### 步骤 3：初始化数据目录

**关键步骤：此步骤可防止"磁盘写入失败"错误！**

```bash
# 运行初始化脚本（推荐）
./init.sh

# 或手动设置
mkdir -p data/{saves,game,steam,logs}
chown -R 1000:1000 data/
```

#### 步骤 4：启动服务器

```bash
# 启动服务器
docker compose up -d

# 查看日志
docker logs -f puppy-stardew
```

**如果启用了 Steam 令牌**，您需要输入验证码：

```bash
docker attach puppy-stardew
# 粘贴您的 Steam 令牌代码并按回车
# 重要：不会显示任何内容 - 这是正常的！
# 等待几秒钟，游戏会自动开始下载
# 按 Ctrl+P Ctrl+Q 分离（不是 Ctrl+C！）
```

</details>

## 初始设置（仅首次运行）

服务器启动后，您需要**一次性**创建或加载存档：

1. **连接到 VNC：**
   - 地址：`服务器IP:5900`
   - 密码：您在 `.env` 文件中设置的 `VNC_PASSWORD`
   - VNC 客户端：[RealVNC](https://www.realvnc.com/en/connect/download/viewer/)、[TightVNC](https://www.tightvnc.com/) 或任何 VNC 查看器

2. **在 VNC 窗口中：**
   - 创建新农场，或
   - 加载现有存档

3. **加载完成后：**
   - ServerAutoLoad 模组会记住您的存档
   - 以后重启会自动加载此存档
   - Always On Server 会自动启用 Auto Mode
   - 您可以断开 VNC 连接了

4. **玩家现在可以连接了！**
   - 打开星露谷物语
   - 点击"合作" → "加入局域网游戏"
   - 服务器会自动出现在列表中
   - 或手动输入服务器IP：`192.168.1.100`（示例）
   - **重要说明**：
     - 只需输入IP地址，**不需要加端口号**（不是`192.168.1.100:24642`）
     - 自动使用24642/UDP端口
     - 如需内网穿透或端口转发，必须转发**UDP协议**（不是TCP）

## 包含内容

### 预装模组

| 模组 | 版本 | 用途 | 主要功能 |
|-----|------|------|--------|
| **Always On Server** | v1.20.3 | 保持服务器 24/7 运行，不需要房主在线 | 无人值守服务器运行 |
| **AutoHideHost** | v1.2.2 | 自定义模组 - 隐藏房主玩家并启用即时睡眠 | 无缝昼夜过渡 |
| **ServerAutoLoad** | v1.2.1 | 自定义模组 - 启动时自动加载存档 | 无需手动VNC加载 |
| **✨ Skill Level Guard** | v1.4.0 | **新版** - 防止Always On Server强制升到10级并实现自动启用 | 基于经验值精确计算等级 + Auto Mode自动启用 |

**v1.0.58 新功能：**
- 🎉 **已修复**：Always On Server容器重启后自动启用
- ✅ **新增**：Skill Level Guard v1.4.0通过反射调用ToggleAutoMode
- ✅ **已验证**：游戏在无玩家时正确暂停
- ✅ **已测试**：ServerAutoLoad和Always On Server协同工作正常

所有模组都已预配置，开箱即用！

## 常用操作

<details>
<summary><b>查看服务器日志</b></summary>

```bash
# 实时日志
docker logs -f puppy-stardew

# 最后 100 行
docker logs --tail 100 puppy-stardew
```
</details>

<details>
<summary><b>重启服务器</b></summary>

```bash
docker compose restart
```
</details>

<details>
<summary><b>停止服务器</b></summary>

```bash
docker compose down
```
</details>

<details>
<summary><b>更新到最新版本</b></summary>

```bash
docker compose down
docker pull truemanlive/puppy-stardew-server:latest
docker compose up -d
```
</details>

<details>
<summary><b>备份存档</b></summary>

```bash
# 手动备份
tar -czf backup-$(date +%Y%m%d).tar.gz data/saves/

# 或使用备份脚本（运行 quick-start.sh 后可用）
./backup.sh
```
</details>

## 故障排除

<details>
<summary><b>错误："Disk write failure" 下载游戏时</b></summary>

**原因**：数据目录权限不正确。

**解决方法**：
```bash
chown -R 1000:1000 data/
docker compose restart
```

容器以用户 ID 1000 运行，所以文件必须归 UID 1000 所有。
</details>

<details>
<summary><b>需要 Steam 令牌代码</b></summary>

如果您启用了 Steam 令牌：

```bash
docker attach puppy-stardew
# 粘贴您邮箱/手机应用中的代码并按回车
# 重要：不会显示任何输出 - 这是正常的！
# 等待几秒钟，游戏会自动开始下载
# 按 Ctrl+P Ctrl+Q 分离（不是 Ctrl+C！）
```

**提示**：建议使用 Steam 令牌手机应用，获取代码更快。
</details>

<details>
<summary><b>游戏无法启动</b></summary>

1. 检查日志：`docker logs puppy-stardew`
2. 验证 `.env` 中的 Steam 凭证
3. 确保您在 Steam 上拥有星露谷物语
4. 检查磁盘空间：`df -h`
5. 重启：`docker compose restart`
</details>

<details>
<summary><b>玩家无法连接</b></summary>

1. **检查防火墙**：端口 `24642/udp` 必须开放
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 24642/udp

   # CentOS/RHEL
   sudo firewall-cmd --add-port=24642/udp --permanent
   sudo firewall-cmd --reload
   ```

2. **验证服务器正在运行**：
   ```bash
   docker ps | grep puppy-stardew
   ```

3. **检查存档是否已加载**：通过 VNC 连接或检查日志中的 "Save loaded"

4. **确保游戏版本匹配**：服务器和客户端必须是相同的星露谷物语版本
</details>

<details>
<summary><b>Always On Server 未自动启用</b></summary>

**v1.0.58 已修复此问题！**

如果更新后仍然出现：

1. **拉取最新镜像**：
   ```bash
   docker compose down
   docker pull truemanlive/puppy-stardew-server:latest
   docker compose up -d
   ```

2. **检查模组版本**：
   ```bash
   docker logs puppy-stardew | grep "Skill Level Guard"
   # 应该显示 v1.4.0
   ```

3. **查看启用日志**：
   ```bash
   docker logs puppy-stardew | grep "Auto mode on"
   # 应该显示 "Auto mode on!" 消息
   ```
</details>

## 高级配置

<details>
<summary><b>自定义模组设置</b></summary>

模组配置文件在容器内的 `/home/steam/stardewvalley/Mods/` 目录：

```bash
# 编辑 AutoHideHost 配置
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/AutoHideHost/config.json

# 编辑 Always On Server 配置
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/AlwaysOnServer/config.json

# 编辑 ServerAutoLoad 配置
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/ServerAutoLoad/config.json
```

编辑后重启服务器：
```bash
docker compose restart
```
</details>

<details>
<summary><b>更改端口号</b></summary>

编辑 `docker-compose.yml`：

```yaml
ports:
  - "24642:24642/udp"  # 更改第一个数字为您想要的端口
  - "5900:5900/tcp"    # VNC 端口
```

更改后重启：
```bash
docker compose up -d
```
</details>

<details>
<summary><b>设置完成后禁用 VNC</b></summary>

编辑 `.env`：
```env
ENABLE_VNC=false
```

重启：
```bash
docker compose up -d
```

这可以节省约 50MB 内存。
</details>

## 系统要求

**服务器：**
- **CPU**：1+ 核心（4+ 玩家推荐 2+）
- **内存**：最低 2GB（4+ 玩家推荐 4GB）
- **磁盘**：2GB 可用空间
- **操作系统**：Linux、Windows（Docker Desktop）、macOS（Docker Desktop）
- **网络**：开放端口 24642/UDP（VNC 需要 5900/TCP）

**客户端：**
- 星露谷物语（任何平台：PC、Mac、Linux、iOS、Android）
- 与服务器相同的游戏版本（1.6.15）
- 局域网或互联网连接到服务器

## 许可证与法律

**许可证**：MIT 许可证 - 免费使用、修改和分发。

**重要法律说明：**
- 您必须在 Steam 上拥有星露谷物语
- 游戏文件通过您的 Steam 账户下载
- 这不是盗版工具
- 模组遵循其原始许可证：
  - Always On Server：[GPL-3.0](https://github.com/funny-snek/Always-On-Server-for-Multiplayer)
  - ServerAutoLoad：MIT（本项目自定义模组）
  - AutoHideHost：MIT（本项目自定义模组）
  - Skill Level Guard：MIT（本项目自定义模组）

## 致谢

- **星露谷物语** by [ConcernedApe](https://www.stardewvalley.net/)
- **SMAPI** by [Pathoschild](https://smapi.io/)
- **Always On Server** by funny-snek & Zuberii
- **Docker** by Docker, Inc.

## 贡献

欢迎贡献！请：

1. Fork 本仓库
2. 创建功能分支
3. 提交 Pull Request

## 支持与社区

- **错误报告**：[GitHub Issues](https://github.com/truman-world/puppy-stardew-server/issues)
- **问题讨论**：[GitHub Discussions](https://github.com/truman-world/puppy-stardew-server/discussions)
- **Docker Hub**：[truemanlive/puppy-stardew-server](https://hub.docker.com/r/truemanlive/puppy-stardew-server)

## Star 历史

如果这个项目帮助了您，请考虑给个 Star！⭐

---

<div align="center">

**为星露谷物语社区用爱制作**

Made with ❤️ for the Stardew Valley Community

</div>
