# Bear Booster —— 已发布版本的对应源码（GPL-3.0）

本仓库**只做一件事**：为已发布的 Bear Booster 二进制（Android APK / Windows 安装包）提供
**逐版本对应的完整源码快照**，以履行 GPL-3.0 的源码提供义务。

- Bear Booster 是基于 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的 **GPL-3.0 修改版**；
- 内核为 [mihomo / Clash.Meta](https://github.com/MetaCubeX/mihomo)（GPL-3.0）的一个分支；
- 开发仓库为私密仓库，**构建所需的全部源码在这里以快照形式公开提供**，未做任何闭源修改。

## 发布版本对照表

| 版本 | 标签 | 应用源码 commit | 内核源码 commit | 构建依赖 |
| --- | --- | --- | --- | --- |
| 0.9.2（T15：客户端更新订阅时自动选择最快镜像） | `v0.9.2-t15` | `f4028e1551865371a9aa898c7cf0c92b4da30498` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |
| 0.9.2（T14：默认新安装使用直连入口） | `v0.9.2-t14` | `624abbcb4b441217187385e1615ebf461ede54b4` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |
| 0.9.2（T13：构建脚本注入正式版本号） | `v0.9.2-t13` | `0d4d558a0d77f3c1890f3f8e4e9ae32b874b06d2` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |
| 0.9.2（T12：无障碍与图标命名修正） | `v0.9.2-t12` | `b89062a2f29cf49f2e679ee9f28a689f629875a7` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |
| 0.9.2（T11：账号页展示长期主页地址） | `v0.9.2-t11` | `7fc0411c80306a1e8263a909fbb1516db68d0824` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |
| 0.9.2（T10：彻底移除首次启动免责横幅） | `v0.9.2-t10` | `4f1ce25d75c2574bd73009f54231491e1d434830` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |
| 0.9.2（T9：安装包与官网下载同字节） | `v0.9.2-t9` | `51e3210c7f0c20c407c541df5ad22c4a2651678f` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |
| 0.9.2（T8：CI 输出安装包清单注解） | `v0.9.2-t8` | `9ca290e7287a8c36bab9486039ddfcaf2643add5` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |
| 0.9.2（T7：首次发布安卓安装包） | `v0.9.2-t7` | `e504e2e84b90654bc105372e851c6ac61fc652ba` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |
| 0.9.2（T6：修正登录取订阅的模板类型，节点不再为空） | `v0.9.2-t6` | `e4a67ebf27af569170540d1e55ae5a6ad452dd6a` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |
| 0.9.2（T5：Windows 窗口标题与安装器品牌） | `v0.9.2-t5` | `bdf292293804172ce23c3600a9e981dd5dd871c3` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |
| 0.9.2（T4：安装包内置面板地址） | `v0.9.2-t4` | `28023bbf44a5d270cb6586dbc1b9f4fb0f277e1c` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |
| 0.9.2（T3：移除上游 Telegram 入口、关闭应用内对上游更新的宣传） | `v0.9.2-t3` | `2f853500a4e8290ed7b93180ce394dc66db5bce1` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |
| 0.9.2（T2：修正「关于」页源码链接） | `v0.9.2-t2` | `9ef280a969a0cac04f55c1cc7d30edfb31edaee6` | `c5062921054902b25215a6a933e72ccd714c9bfa` | Flutter 3.47.6 / Dart 3.13.5 / Go 1.27.1 / NDK r28c / Rust stable / JDK 17 |
| 0.9.2（T1：一键接入） | `v0.9.2-t1` | `cc73f1b9cc06143f44b9f8294a78b43aa5b348cf` | `c5062921054902b25215a6a933e72ccd714c9bfa` | 同上 |

每个版本的**全部**安装包（T2 起为 3 个 APK + 安装程序 + 便携包）都由上表该版本的
应用源码 commit **同一个提交**构建，附件与源码严格一一对应。

## 源码快照文件（在各版本的 Release 附件里）

| 版本 | 文件 | 大小 | SHA-256 |
| --- | --- | --- | --- |
| T15 | `bearbooster-0.9.2-t15-source.zip` | 23.3 MB | `C991044694C30621555F5D52FDC9ABDE184F2E01DE60F06A086082DF2B8DB00C` |
| T15 | `bearbooster-0.9.2-t15-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T14 | `bearbooster-0.9.2-t14-source.zip` | 22.2 MB | `3911A53AC2B1C8789DCDD838F4E6869872B71D32B05AB55CBCBB6581396987AF` |
| T14 | `bearbooster-0.9.2-t14-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T13 | `bearbooster-0.9.2-t13-source.zip` | 22.2 MB | `6B8DF02F975CAC766AC120F6D4D6A15DB264BBD35051B84D0DDC7FD3FFC80EBB` |
| T13 | `bearbooster-0.9.2-t13-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T12 | `bearbooster-0.9.2-t12-source.zip` | 22.2 MB | `115A5D4071BEBF8F45A79F775D8BD1F3DF18CCAB33E9ECA7E31707D6732F0127` |
| T12 | `bearbooster-0.9.2-t12-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T11 | `bearbooster-0.9.2-t11-source.zip` | 22.2 MB | `EBCA2FB6A16F4440E261EA41B2EB693245D86D9388748EEA81607AB941920901` |
| T11 | `bearbooster-0.9.2-t11-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T10 | `bearbooster-0.9.2-t10-source.zip` | 22.2 MB | `284861A61B050A2775E35778A65D73581D70A3E069B3E749368DE95E27161957` |
| T10 | `bearbooster-0.9.2-t10-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T9 | `bearbooster-0.9.2-t9-source.zip` | 22.2 MB | `8B8CEF89CF4E50019E5DC66AF6B50F6B4BAA17E5BA2CD6328A1CF19F5312B356` |
| T9 | `bearbooster-0.9.2-t9-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T8 | `bearbooster-0.9.2-t8-source.zip` | 22.2 MB | `152B23CA742821D55362101C3BF7F01708A07AEADE66C87118CEF3D5403FF17F` |
| T8 | `bearbooster-0.9.2-t8-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T7 | `bearbooster-0.9.2-t7-source.zip` | 22.2 MB | `61BA3A24DD9817D89839904C84A4FE6C04926FDA5E299492376E3CF2B2E96FDC` |
| T7 | `bearbooster-0.9.2-t7-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T6 | `bearbooster-0.9.2-t6-source.zip` | 22.2 MB | `A037B5C42E1F329BB2C3265FA086FD7EF7E76EE7E3E6354FFD3C8B048EC109C5` |
| T6 | `bearbooster-0.9.2-t6-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T5 | `bearbooster-0.9.2-t5-source.zip` | 22.2 MB | `29FA7DE77844CE1772EC8C28700E6BBAD8FBA90A3BC49DA7460CEF2F868FE6E8` |
| T5 | `bearbooster-0.9.2-t5-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T4 | `bearbooster-0.9.2-t4-source.zip` | 22.2 MB | `6927C94400DC783DDB0F3A09237FA2DD6D0F6200CB08BAE6443EFFA6A9969E67` |
| T4 | `bearbooster-0.9.2-t4-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T3 | `bearbooster-0.9.2-t3-source.zip` | 22.2 MB | `7E40133096251380F32E83BF93D5FF12B2CD38E5AC5A8E35F0FCCE07F0BF7B1B` |
| T3 | `bearbooster-0.9.2-t3-core-source.zip` | 1.7 MB | `928D50D0223781EB607BED01150A75FB99271EE0996A94325D6088F0448145D1` |
| T2 | `bearbooster-0.9.2-t2-source.zip` | 22.3 MB | `6A2AD86904AA002549D6CF9FF6FC4D0138B9B8B6DB8EC8D22119FF9DED498ED8` |
| T2 | `bearbooster-0.9.2-t2-core-source.zip` | 1.7 MB | `DA853A53BE64DF95715B158B00816E17AB9C138CCB1B1799AAAF72109B6C7666` |
| T1 | `bearbooster-0.9.2-t1-source.zip` | 22.3 MB | `3294E706AF28DD9BDE3C195C6609BC3DFB70A2B3EED46CE9BB78E362F91732F1` |
| T1 | `bearbooster-0.9.2-t1-core-source.zip` | 1.7 MB | `DA853A53BE64DF95715B158B00816E17AB9C138CCB1B1799AAAF72109B6C7666` |

每个版本的 `-source.zip` 是应用本体（Flutter/Dart + Android/Windows 工程，含全部构建脚本与 CI 定义），
`-core-source.zip` 是内核子模块在该 commit 上的源码。两者合起来即为对应源码（Corresponding Source）。

**核验说明（2026-11-07，T15 于 2026-11-09 补充）**：已对公开 Release 的 T7–T14 附件执行 ZIP 可读性、文件清单与逐文件字节核对。
T7–T12、T14 的应用源码与上表标签的 Git 树一致，T7–T14 的内核源码与 `c5062921054902b25215a6a933e72ccd714c9bfa` 一致。
T13 的公开应用 ZIP 仅 `test/setup_test.dart` 与其标签树存在测试调用差异，未改写发布附件；其余文件一致。

T15 的 `-source.zip` 已确认包含 `f4028e1551865371a9aa898c7cf0c92b4da30498` 的应用源码；该 ZIP 由 Windows 侧打包，文本文件为 CRLF 换行，与 Git 树的 LF 版本在规范化换行后内容一致，因此 ZIP 文件本身与 Git 树不是逐字节相同。`-core-source.zip` 仍对应 `c5062921054902b25215a6a933e72ccd714c9bfa`。

源码 SHA-256 已同步至 `SHA256SUMS.txt`，用于核对下载文件。

安装包自身的 SHA-256 见同版本 Release 里的 `SHA256SUMS.txt`。

## 怎么构建（与 CI 一致）

1. **应用**：解压 `bearbooster-*-source.zip`，在目录内
   - 把 `-core-source.zip` 解到 `core/Clash.Meta/`；
   - `flutter pub get`；
   - Android：`flutter build apk --release --dart-define=PANEL_BASE_URL=<你的面板地址>`；
   - Windows：`flutter build windows --release`。
   - Go 内核使用 `CGO_ENABLED=0` 构建；Android 需要 NDK r28c 与 JDK 17。
   - 仓库自带的 `setup.dart` 走 `--dart-define-from-file=env.json`，它会把环境变量
     `PANEL_BASE_URL`（若已设置）写进该文件；CI 用的就是这条路径。不设置时行为与以前完全一致。
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
## 各版本改动摘要

- **T6**：登录后取订阅时请求 Clash.Meta 模板；此前固定请求经典 Clash 模板，而本面板只提供 VLESS 节点，经典模板会把这些节点全部丢弃，导致节点列表为空；
- **T5**：Windows 窗口标题改为「白熊加速」；安装器命名与 `BearBooster.exe` 对齐、`publisher_url` 指向本仓库；CI 测试清单加入 `test/setup_test.dart`（并修掉它暴露的环境变量冲突）；
- 更早的 T1–T4 见上表与各自的 Release 说明。