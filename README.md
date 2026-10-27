# Bear Booster —— 已发布版本的对应源码（GPL-3.0）

本仓库**只做一件事**：为已发布的 Bear Booster 二进制（Android APK / Windows 安装包）提供
**逐版本对应的完整源码快照**，以履行 GPL-3.0 的源码提供义务。

- Bear Booster 是基于 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的 **GPL-3.0 修改版**；
- 内核为 [mihomo / Clash.Meta](https://github.com/MetaCubeX/mihomo)（GPL-3.0）的一个分支；
- 开发仓库为私密仓库，**构建所需的全部源码在这里以快照形式公开提供**，未做任何闭源修改。

## 发布版本对照表

| 版本 | 标签 | 应用源码 commit | 内核源码 commit | 构建依赖 |
| --- | --- | --- | --- | --- |
| 0.9.2（T1 一键接入） | `v0.9.2-t1` | `cc73f1b9cc06143f44b9f8294a78b43aa5b348cf` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |

## 源码快照文件（在各版本的 Release 附件里）

| 文件 | 大小 | SHA-256 |
| --- | --- | --- |
| `bearbooster-0.9.2-t1-source.zip` | 22.3 MB | `3294E706AF28DD9BDE3C195C6609BC3DFB70A2B3EED46CE9BB78E362F91732F1` |
| `bearbooster-0.9.2-t1-core-source.zip` | 1.7 MB | `DA853A53BE64DF95715B158B00816E17AB9C138CCB1B1799AAAF72109B6C7666` |

第一个是应用本体（Flutter/Dart + Android/Windows 工程，含全部构建脚本与 CI 定义）；
第二个是内核子模块在该 commit 上的源码。两者合起来即为对应源码（Corresponding Source）。

## 怎么构建（与 CI 一致）

1. **应用**：解压 `bearbooster-*-source.zip`，在目录内
   - `git submodule` 对应的内核源码用 `core-source.zip` 解到 `core/Clash.Meta/`；
   - `flutter pub get`；
   - Android：`flutter build apk --release --dart-define=PANEL_BASE_URL=<你的面板地址>`；
   - Windows：`flutter build windows --release`。
   - Go 内核使用 `CGO_ENABLED=0` 构建；Android 需要 NDK r28c 与 JDK 17。
2. **签名**：发布版 APK 使用发布者私钥签名。**签名密钥不属于对应源码**，因此不在此仓库中
   （GPL-3.0 只要求提供构建所需源码，不要求提供私钥）。源码的 CI 定义里出现的
   `STORE_PASSWORD` / `KEY_PASSWORD` / `KEYSTORE` / `KEY_ALIAS` 只是 **GitHub Actions 的变量名**，
   用于注入签名材料；本仓库**不含任何密钥值**。

## 许可与归属

- 本修改版整体以 **GPL-3.0** 发布，见 [LICENSE](LICENSE)；
- 原始项目版权归 FlClash / mihomo 各作者所有；
- 修改部分（品牌、一键接入等）版权归本仓库维护者，同样以 GPL-3.0 授权。

## 联系方式

需要源码、构建帮助或发现本仓库缺少某个已发布版本，请开 **Issue**。
（已发布但尚未在此登记对应源码的版本，我们会补上。）