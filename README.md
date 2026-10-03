# 电路守线

小型原创三行六列战术游戏，三设施、三目标类型和五个固定波次。能源站 50、每 8 秒生成 25 能量；脉冲塔 75、每秒发射 20 伤害；护盾墙 50、300 生命。卡片冷却 5 秒，掉落 10 秒过期，天空每 10 秒补能。最右列不可布置，铲除不退款。每行一次自动清线保护，用尽后再次越线失败；全部波次生成且目标清除才胜利。三个任务逐步加入护甲和快速目标。

本项目沿用旧目录和 package 名 shadow_pvz 以保留兼容性；本轮正式产品是原创电路守线，不是经典 Plants vs. Zombies 重制，不复制 ShadowGamePvZ 的私有素材或大型 Godot/C++ 战斗实现。

## 操作与本地数据

触控、鼠标和键盘可操作真实按钮。棋格支持 Tab 进入、方向键移焦点、Enter 或空格确认；密室移动另用 WASD/E。Esc 暂停，离开标签页暂停后需手动继续。声音默认关闭，由右上角开关启用。对局进度与最近 50 条结果只保存在当前站点、当前设备；存储不可用时页面会提示，本页关闭后无法保证恢复。

游戏中心仅负责目录；独立游戏可以通过左上角返回中心。没有联机后端，也没有云同步或在线排行榜。

## 工程与构建

`lib/lane_defense.dart` 的 `LaneDefense`：资源、冷却、生成排期、射击与接触伤害、保护、终局和完整战局恢复。旧麒麟与地图实验代码保留，但入口已切换为电路守线。

正式主题为 Frequency Terminal，中文清晰操作区域使用黑色、酸黄和琥珀语义色。Web 平台适配器通过条件导入使用 Dart JSInterop，`web/game_bridge.js` 负责 localStorage、短提示音和白名单站内导航；不要删除 index.html 中该桥接脚本。

运行图像由内置 ImageGen 生成并压缩为 WebP；仅运行资源在 assets，原图、提示词与 QA 报告位于仓库外。

构建前在兼容 Flutter SDK 上取得现有依赖并运行分析、测试。Web 输出放仓库外，正式项目部署 base 保持：

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href /XJY.GAME.PVZ.pvz_flutter/ --output /absolute/external/build/XJY.GAME.PVZ.pvz_flutter
```

超级仓库并行开发时，Flutter SDK、pubspec/lock 与测试命令由统一升级会话串行执行。构建成功仍需真实浏览器验收；不得在失败或验收前覆盖旧 docs。历史重复 CNAME 不代表该子项目应部署为共享域名根路径。

## 验收状态

本轮源码已写入，分析、规则测试、release 构建及完整浏览器玩法验收由统一流程记录；此 README 不以源码就绪声明已上线。运行时元数据为中文产品真名，旧 docs 仍在成功验收前保留。设计、生成过程、截图与 QA 报告不提交到 Git。
