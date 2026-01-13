# Ubuntu 24.04 截图软件全指南


---

### 📸 默认截图工具（GNOME Screenshot）
Ubuntu 24.04 预装了GNOME桌面环境的截图工具，无需额外安装，功能简洁实用。

**核心快捷键（一键操作）**：
| 快捷键 | 功能 | 保存位置 |
|-------|------|---------|
| **PrtSc** | 截取全屏 | ~/Pictures/Screenshots |
| **Alt+PrtSc** | 截取当前活动窗口 | ~/Pictures/Screenshots |
| **Shift+PrtSc** | 截取自定义区域 | ~/Pictures/Screenshots |
| **Ctrl+PrtSc** | 截图到剪贴板（不保存文件） | - |
| **Shift+Ctrl+PrtSc** | 区域截图到剪贴板 | - |
| **Ctrl+Alt+E** | 延时截图（可设置秒数） | 按需选择保存/剪贴板 |
| **Shift+Ctrl+Alt+R** | 屏幕录制（再次按停止） | ~/Videos |

**高级使用**：
1. 按PrtSc后出现截图面板，可选择：全屏、窗口、区域三种模式
2. 支持设置延时（1-10秒），方便捕获菜单等动态内容
3. 可直接复制到剪贴板或保存为文件
4. 简单编辑功能：裁剪、旋转、添加文字等

---

### 🔥 推荐第三方截图工具（功能增强）

#### 1. Flameshot（最佳推荐）
功能强大的开源截图标注工具，支持丰富的编辑功能，Ubuntu官方文档推荐。

**安装**：
```bash
sudo apt update && sudo apt install flameshot -y
```

**核心功能**：
- 自由选区、全屏、窗口、屏幕录制
- 标注工具：箭头、矩形、圆形、文字、马赛克、模糊、像素化
- 一键上传到Imgur（可选），自动复制链接
- 自定义快捷键：设置`flameshot gui`为Ctrl+Alt+A（类似Windows QQ截图）
- 支持命令行操作：`flameshot full -p ~/Pictures`（全屏截图保存到指定目录）

#### 2. Shutter（经典全能工具）
功能丰富的老牌截图软件，适合需要高级编辑和批量处理的用户。

**安装**：
```bash
sudo apt install shutter -y
```

**核心功能**：
- 支持多种截图模式（区域、窗口、全屏、菜单、网页）
- 内置图片编辑器：添加水印、调整尺寸、滤镜效果
- 支持插件扩展和脚本自动化
- 截图历史记录管理

#### 3. Peek（GIF录制专用）
轻量级屏幕录制工具，专注于生成GIF动画，适合演示操作步骤。

**安装**：
```bash
sudo apt install peek -y
```

**核心功能**：
- 录制自定义区域为GIF/MP4/WebM格式
- 可调帧率（5-30fps）和质量
- 自动优化文件大小，适合分享

#### 4. Spectacle（KDE用户首选）
KDE桌面环境的默认截图工具，适合使用Kubuntu 24.04的用户。

**安装**：
```bash
sudo apt install spectacle -y
```

**核心功能**：
- 多模式截图：全屏、窗口、区域、自由形状
- 高级编辑：注释、高亮、模糊、裁剪
- 支持截图后直接分享到社交媒体

---

### ⚙️ 自定义快捷键设置
若想使用类似Windows的Ctrl+Alt+A截图体验，可按以下步骤设置：

1. 打开**设置** → **键盘** → **查看并自定义快捷键** → **自定义快捷键**
2. 点击"+"添加新快捷键：
   - 名称：Flameshot截图
   - 命令：`flameshot gui`
   - 快捷键：按下Ctrl+Alt+A组合键
3. 保存后立即生效

---

### 🛠️ 命令行截图工具（自动化场景）
适合脚本、服务器环境或批量处理：

#### 1. scrot（轻量高效）
```bash
sudo apt install scrot -y
```
**常用命令**：
```bash
scrot ~/Pictures/fullscreen.png  # 全屏截图
scrot -s ~/Pictures/area.png     # 区域截图
scrot -u ~/Pictures/window.png   # 窗口截图
scrot -d 5 ~/Pictures/delay.png  # 5秒延时截图
```

#### 2. gnome-screenshot（命令行版）
```bash
gnome-screenshot -f ~/Pictures/test.png  # 保存全屏
gnome-screenshot -w -f ~/Pictures/window.png  # 窗口截图
gnome-screenshot -a -f ~/Pictures/area.png  # 区域截图
```

---

### 总结与选择建议
| 使用场景 | 推荐工具 | 理由 |
|---------|---------|------|
| 日常基础截图 | 默认GNOME截图 | 无需安装，快捷键便捷 |
| 技术文档/教程 | Flameshot | 标注功能强大，适合说明 |
| GIF演示 | Peek | 轻量高效，专注GIF制作 |
| 批量处理/脚本 | scrot | 命令行操作，易于自动化 |
| KDE桌面 | Spectacle | 原生适配，功能全面 |


