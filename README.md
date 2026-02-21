# Caelestia Modded

基于 [Caelestia Shell](https://github.com/caelestia-dots/shell) 的魔改版本。

## 改动内容

### 启动台 (Launcher)
- 搜索栏中文化，自定义 App Store 图标（适配深色/浅色模式）
- 应用以网格图标视图展示（支持小/中/大图标切换）
- 分类标签栏，按分类浏览应用
- 搜索结果也以网格展示
- 三点菜单：排序方式、图标大小、新建分类、更换壁纸、隐藏应用管理、系统设置
- 右键应用图标：隐藏应用、移动到分类、恢复默认分类
- 右键分类标签：重命名、删除
- 隐藏应用管理页面（右键可恢复）
- 右键菜单修复：不再默认高亮第一项
- 神灯风格展开/收起动画
- 所有设置持久化保存到 `~/.config/caelestia/shell.json`

### 任务栏 (Bar)
- 实时歌词显示：中文竖排（标点自动转竖排形式）、英文旋转横排，逐行自动切换
- 歌词从网易云音乐 API 获取，与播放进度同步
- 超出显示区域的歌词自动滚动
- 可通过 `lyricsMode` 配置切换歌词/窗口标题模式
- 音量/亮度图标显示，禁用滚轮调节
- 点击时钟弹出日历面板

### 通知 (Toasts)
- 通知弹窗支持毛玻璃/半透明效果，跟随系统透明度设置

### 会话管理 (Session)
- 注销命令改为 `uwsm stop`

### 深色/亮色模式切换
- 智能 flavour 切换：catppuccin latte ↔ mocha，rosepine dawn ↔ main
- 不再报错 "Scheme xxx 没有 dark 模式"

### 其他
- 启动台居中弹窗显示，自带背景
- 移除底部热区触发（仅快捷键打开）

## 安装

需要先安装原版 `caelestia-shell`。

```bash
git clone <本仓库>
cd caelestia-modded
sudo ./install.sh
```

## 卸载（恢复原版）

```bash
sudo ./uninstall.sh
```

## 依赖

- caelestia-shell
- quickshell
- hyprland
- python3（歌词获取）
