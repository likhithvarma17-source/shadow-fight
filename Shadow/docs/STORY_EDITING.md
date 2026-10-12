# 《影》剧情配置编辑指南

当前剧情文本的唯一数据源是 [`data/story.xml`](../data/story.xml)。选择 XML 不是因为它普遍优于所有格式，而是因为当前需求同时需要**人工可读、允许注释、重复对白易增删排序、支持多场景与可选字段，并且 Godot 4 可以原生解析而无需增加第三方库**。JSON 也能运行，但不支持注释；CSV 适合表格，却不适合多段场景和不同说话目标；Godot `.tres` 更适合编辑器工具，不适合直接手写中文对白。

游戏已经全局内置 **Fusion Pixel Font 12px Proportional `zh_hans`** 完整简体中文字形。你可以直接在 XML 中加入新的常用或生僻汉字，不需要重建字体子集；标题、独立前景任务简报、对白气泡、HUD、暂停菜单和调参面板都会使用同一套像素字体。背景中的翻盖手机只是虚焦氛围图，不限制文字位置或长度。

教程屋顶的闪电现身惊呼由 `scene id="tutorial_materialize"` 控制：电视幕打开时左侧暂时无人，闪电落下后影出现，程序先播放这段，再播放 `tutorial_arrival` 的正式质问。`target="blade"` 会让对白跟随第一名赤井帮打手；可直接增删或重写其中的 `<line>`。

## 最常用的改法

每句对白都是一个 `<line>`。直接修改标签中间的文字即可；复制、删除或上下移动整行，就能增加、删除或调整播放顺序。简报、教程、室内第一层及首领对白都会逐字显示并播放轻微电子提示音；文字尚未完成时按 `J` 会立即显示整句，随后出现 `J // 继续`，再次按 `J` 才进入下一句。室内第二至五层使用不会暂停战斗的普通 NPC 气泡：NPC 一进入镜头就开始说话，早于该层警报，`duration` 控制每句停留时间；动态漫画也继续使用 `duration` 控制每幕停留时间。

```xml
<scene id="tutorial_arrival" mode="world">
  <line target="blade" speaker="赤井帮打手" duration="2.8">你是谁？赶紧滚。</line>
	<line target="player" speaker="影" duration="1.4">……</line>
</scene>
```

| 字段 | 用途 | 是否必填 |
|---|---|---|
| `scene id` | 程序查找这一段剧情的稳定名称 | 是；修改现有 ID 会让对应剧情无法播放 |
| `mode` | 说明这是 `phone` 简报还是 `world` 场景对白 | 建议保留 |
| `target` | 气泡跟随的角色：`blade`、`player`、`gunner`、`reinforcement_lead`、`boss`，或室内楼层成员 `member_0`、`member_1`、`member_2` | 世界对白必填 |
| `speaker` | 显示在台词上方的小型身份标签 | 可选 |
| `duration` | 室内第二至五层 NPC 气泡及动态漫画每幕的停留秒数；J 键剧情对白保留此字段但不自动跳过 | 建议填写 |
| 标签正文 | 玩家实际看到的文字，可直接换行 | 是 |

> 主角的无台词设定使用 `<line target="player">……</line>` 表示。这样主角永远只呈现沉默，不需要专门写一句“主角没有说话”。

## 修改第一关敌人狠话

`<barks role="blade">` 与 `<barks role="gunner">` 分别保存近战打手和枪手的狠话。第一关会按出现顺序循环分配，但每个敌人接近玩家时只有 **56%** 概率真正说出口；一次判定为沉默后不会逐帧重抽。出现的台词显示 3 秒，敌人提前死亡时立即消失。

```xml
<barks role="gunner">
  <line duration="3.0">别动！再动我就开枪！</line>
  <line duration="3.0">赤井帮的货，你也敢碰？</line>
</barks>
```

新增一句只需要复制一行。删除一句不会影响程序。调整顺序会改变敌人获得台词的顺序。

## 修改室内关卡休息对白

第一关屋顶之后会进入五层纵向室内据点。`interior_floor_1` 到 `interior_floor_5` 分别控制五层敌人的聊天内容。每层中的 `member_0`、`member_1`、`member_2` 对应该层按配置顺序生成的敌人；第一层只有两名敌人，不要在那里使用 `member_2`。

```xml
<scene id="interior_floor_2" mode="world">
  <line target="member_0" speaker="赤井帮枪手">楼下是不是有动静？</line>
  <line target="member_1" speaker="赤井帮打手">旧管道而已，继续喝。</line>
  <line target="member_2" speaker="赤井帮枪手">等等……有人上来了！</line>
</scene>
```

第一层仍是正式剧情：对白期间该层敌人保持休息姿态且不会攻击，最后一句按 `J` 结束后才亮起红色警报并进入战斗。第二至五层不同：只要该层任一存活 NPC 进入镜头，XML 台词便以普通白字气泡快速错开显示；此时敌人仍在休息，不出现 `J // 继续`，也不锁定移动、攻击或关卡进度。影再接近该层后才亮起警报并开始战斗，因此玩家能先看见聊天，再迎接攻击。台词数量、说话顺序、`duration` 与文字都可自由调整，但新增第四名说话目标需要程序支持。

## 修改首领战开场对白

首领战开场使用 `scene id="boss_arrival"`。`target="boss"` 让白字气泡跟随守门人，`target="player"` 让气泡跟随影。可以直接改句子、增删 `<line>` 或调整顺序；程序会在电视式黑幕打开到 **2.35:1** 后按这里的顺序播放，全部对白结束后再恢复 **16:9** 并解锁战斗。

```xml
<scene id="boss_arrival" mode="world">
  <line target="boss" speaker="守门人" duration="2.4">你来这里做什么？</line>
  <line target="player" speaker="影" duration="1.3">……</line>
</scene>
```

## 修改首领战结束对白

首领生命归零后，程序先等待死亡动作落地，再以 **2.35:1** 电视开幕播放 `scene id="boss_passed"`。这里同样支持 `target="boss"` 与 `target="player"`，台词数量和文字可以自由增删。最后一句结束后，电视幕闭合并进入固定的仓库漫画剧情。

```xml
<scene id="boss_passed" mode="world">
  <line target="boss" speaker="守门人" duration="3.4">你……似乎能预判我的动作。</line>
  <line target="player" speaker="影" duration="1.3">……</line>
</scene>
```

紧接着的动态漫画使用 `scene id="post_boss_epilogue"`。每个 `<line>` 就是一幕：`speaker` 是左上角幕标题，正文是底部旁白，`duration` 是画面停留秒数，`target` 决定使用哪张画面和运镜。可以直接改文案、时长、顺序，或复制同一 `target` 来重复使用画面。

| 漫画 `target` | 画面 |
|---|---|
| `warehouse` | 影在仓库发现聚光灯下的木箱 |
| `crate` | 影走近木箱、手扶刀柄 |
| `blade` | 影举刀准备销毁货物 |
| `blade_hold` | 保持举刀画面，用于箱内叫声的停顿 |
| `cat` | 木箱打开，出现瑟瑟发抖的三花猫 |

图片本身、每个 target 的推拉方向、电视开闭幕和最终 `TO BE CONTINUED...` 由 `scripts/post_boss_cinematic.gd` 固定。字幕、幕标题、播放顺序与停留时间全部可以在 XML 中调整。

## 新增剧情段落

可以在 `<story>` 内添加新的 `<scene>`，但新场景只有在 GDScript 中调用该 ID 后才会播放。例如先配置：

```xml
<scene id="level_one_exit" mode="world">
	<line target="player" speaker="影" duration="1.2">……</line>
</scene>
```

之后由场景脚本调用 `StoryStore.get_scene("level_one_exit")`。单纯增删**已有场景中的台词**不需要改代码；增加全新的播放节点、分支、镜头或角色入场仍需要一次程序接线。

## 编辑注意事项

XML 标签必须成对存在，属性值必须放在英文双引号中。正文里的中文引号、逗号、感叹号可直接输入；如果需要显示单独的 `&`，请写成 `&amp;`。保存为 UTF-8。不要修改 `story version="1"`，除非数据结构本身发生升级。

修改后可运行以下引擎检查，不需要浏览器自测：

```bash
godot --headless --path . --script test/story_smoke.gd
godot --headless --path . --script test/tutorial_smoke.gd
godot --headless --path . --script test/interior_smoke.gd
pnpm export && pnpm verify-export
```

第一项会检查 XML 能否解析、关键场景是否存在、对白和狠话数量是否合理；第二项会完整验证教程战斗；第三项会验证五层休息对白、提前可见对白、逐字提示音、仅 `J` 推进、逐层警报、17 段纵向平台可达性、平台枪手、高层子弹和首领场景交接；导出检查会确认 `data/story.xml`、室内场景、背景及对白提示音确实被打进 Web PCK。
