# Automation-scripts-for-Aegisub
[![Aegisub](https://img.shields.io/badge/Aegisub-3.2.2-blue)](https://github.com/Aegisub/Aegisub/releases/tag/v3.2.2)
![GitHub last commit](https://img.shields.io/github/last-commit/zhang-changwei/Automation-scripts-for-Aegisub)
![GitHub all releases](https://img.shields.io/github/downloads/zhang-changwei/Automation-scripts-for-Aegisub/total)
![GitHub](https://img.shields.io/github/license/zhang-changwei/Automation-scripts-for-Aegisub)
![GitHub Repo stars](https://img.shields.io/github/stars/zhang-changwei/Automation-scripts-for-Aegisub?style=social)

## __目录__
  - [__前言__](#前言)
  - [__使用方法__](#使用方法)
  - [__更新日志__](#更新日志)

## __前言__
* __当前各脚本版本信息__
    | Name                            | Version |
    |---------------------------------|---------|
    | C Change SUB resolution to match video PATCH | v1.3 |
    | C Effect                        | v1.6    |
    | C Fast Tools                    | v1.2.1  |
    | C Font Resize (Mocha Deshaking) | v1.3    |
    | C Gradient                      | v2.2    |
    | C Jump                          | v1.0    |
    | C Merge Bilingual SUBS          | v1.2    |
    | C Translation                   | v3.2.1  |
    | C Utilities                     | v1.7.5  |
    <!-- | C XML Analyzer                  | v1.5.2  | -->
    > 在Automation Manager > Description栏中查看脚本版本信息  
    > 第二位数字表示较为重要的更新，如重要功能增加、重大bug修复等  
    > 第三位数字表示小更新
* __下载方式__
    + [![Download](https://img.shields.io/badge/点此下载-orange)](https://github.com/zhang-changwei/Automation-scripts-for-Aegisub/archive/refs/heads/main.zip) 会用Github的请略。
* __使用方法__
    + 将LUA脚本复制到`C:\Program Files (x86)\Aegisub\automation\autoload`路径下，或你的Aegisub安装位置
    + 在 Aegisub Automation 项中可以发现添加的脚本  
    + 可以在`option`中将脚本与热键绑定，建议以脚本首字母绑定热键，方便记忆
* __汉化版__
    + 仓库地址链接 [![Chinese](https://img.shields.io/badge/汉化版-red)](https://github.com/zhang-changwei/Automation-scripts-for-Aegisub-Chinese)，感谢@章鱼哥的汉化。
* __脚本依赖关系__
    + `C Utilities > AE Importer > crop`依赖`imagemagick`，需自行下载，地址[https://imagemagick.org/](https://imagemagick.org/)
    + `C Effect & C Utilities`脚本部分功能依赖`Yutils`库，请先安装相关组件，传送门[https://github.com/Youka/Yutils](https://github.com/Youka/Yutils)，感谢原作者。
    + `C Effect`脚本依赖`xmlSimple`库，原作者[https://github.com/Cluain/Lua-Simple-XML-Parser](https://github.com/Cluain/Lua-Simple-XML-Parser)，本人作了一点修改，存放在`lib`文件夹下，将该文件放置在`C:\Program Files (x86)\Aegisub\automation\include\`目录下即可正常使用。
    <!-- + `lib`目录下`0.png`，`00000000.png`，`ForceTwoWindow.py`为`C XML Analyzer`配套工具，请放置在`C:\Users\?\AppData\Roaming\Aegisub\`目录下。 -->
* __该仓库本人长期维护，欢迎star与fork。__  
* __cheatsheet每次发布release时更新__

-------------------------------------------
## __使用方法__  

参考[wiki](https://github.com/zhang-changwei/Automation-scripts-for-Aegisub/wiki)页

--------------------------------------------
## __更新日志__
| Date | Script | Version | Detail |
|------|--------|---------|--------|
|2022.9.3|C Change SUB resolution to match video PATCH|1.3|增加舍入至3位小数|
|2022.7.23|C Picture Tracker||废弃|
|2022.3.13|C Merge Bilingual|1.2|增加一个更加智能的双语合并器|
|2022.1.8|C Utilities|1.7.5|Dialog Checker 时间轴重叠功能改进|
|2022.1.1|C Translation|3.2.1|美化界面，完善功能|
|2022.1.1|C Gradient|2.2|美化界面，完善功能|
|2021.11.9|C Effect|1.6|bug fix, 优化速度|
|2021.11.2|C Effect|1.4|大幅更新|
|2021.10.22|C Fast Tools|1.2.1|增加selection onward|
|2021.10.5|C Picture Tracker|1.4.1|使用xml记忆config|
|2021.9.25|C Change SUB resolution to match video PATCH|1.2|增加图片缩放适配分辨率|
|2021.9.12|C Picture Tracker|1.4|修复当贴图超出边界时贴图错位|
|2021.9.12|C Scaling Rotating Conflict Solution|1.1|废弃|
|2021.9.12|C Effect|1.2|修复fsp宽度计算问题，加快dissolve渲染速度|
|2021.9.12|C Utilities|1.7.4|界面美化，稳定dialog checker性能，兼容aegisub 3.3.0|
|2021.9.5|C Change SUB resolution to match video PATCH|1.1.1|2160p分辨率尺寸写错了现已改正|
|2021.9.3|C Fast Tools|1.3|增加fad序列功能|
|2021.9.3|C Utilities|1.7.3|自动获取视频fps信息|
|2021.9.2|C Picture Tracker|1.3|支持clip追踪|
|2021.8.24|C Picture Tracker|1.2|图片追踪神器|
|2021.8.24|C Utilities|1.7.2|增加批量裁剪AE图片功能|
|2021.8.11|C Effect|1.1.1|bug修复|
|2021.8.8|C Utilities|1.7.1|优化中文匹配，AE导入支持非从1开始的序列|
|2021.8.7|Effect life game||一个小游戏|
|2021.8.7|C Effect|1.1|加快运行速度，简化无用参数|
|2021.8.4|C Change SUB resolution to match video PATCH|1.1|重大更新，完全重写了代码，无需经过自带的分辨率转换（精度低，有奇妙的bug），运行脚本后手动调整分辨率即可|
|2021.8.2|C Fast Tools|1.1|实现按enter加\N的正常逻辑|
|2021.8.2|C Jump|1.0|行间快速跳转工具|
|2021.7.28|C Utilities|1.7|Move!模块加了一个move2pos按钮，使用更方便，增加删除注释行和调色（实验性）功能，修正了少量bug，加快了运行速度|
|2021.7.27|C Smooth||放弃维护|
|2021.7.27|C Utilities|1.6|SDH,AE Importer更新，Multiline Importer增加从剪切板导入，删掉了Tag Copy功能|
|2021.7.13|C Utilities|1.5.1|摩卡可视化补上了对frz的支持|
|2021.7.10|C Utilities|1.5|加入一大堆新功能|
|2021.7.8|C Utilities|1.4|增添AE序列图导入功能|
|2021.7.8|C Utilities|1.3|增加进度条显示，进一步细分双语checker，改变部分逻辑，加快运行速度，修正了一些bug|
|2021.6.24|C Translation & Gradient| |将`math.power`替换为`^`，以兼容LUA 5.4|
|2021.6.24|C Translation|3.2|乘法for fscx fscy|
|2021.6.24|C Utilities|1.2|功能更新for buffer|
|2021.4.20|C Font Resize|1.3|增加对矢量图的支持|
|2021.4.20|C Effect|1.0|beta 内测版|
|2021.3.20|C Scaling Rotation Conflict Solution|1.1|Bug Fixed|
|2021.3.2|C Translation|3.1|解决字体中"W"导致错误|
|2021.3.1|C Gradient|2.1|解决字体中"W"导致错误，修复 `1vc` 中的 bug，新增对 `t1(\t第1个参数),t2(\t第2个参数),[i]clip` 的支持|
|2021.2.28|C Font Resize|1.2|解决字体中"W"导致错误，增添对样式表中设置fsp值的支持|

<!-- |2022.1.25|C XML Analyzer|1.5.2|封装py为exe程序，可直接运行| -->
<!-- |2022.1.20|C XML Analyzer|1.5.1|增加了强制将一张大图切分成两张小图的功能，与首帧黑屏| -->
<!-- |2021.9.16|C XML Analyzer|1.4.3|bug修复| -->
<!-- |2021.9.16|C XML Analyzer|1.4.1|优化过水| -->
<!-- |2021.9.14|C XML Analyzer|1.3|优化了epoch判断机制| -->
<!-- |2021.9.2|C XML Analyzer|1.2|优化过水，增加时间计算器工具| -->
<!-- |2021.8.24|C XML Analyzer|1.1|修复肉酱分割时存在的一些问题| -->
<!-- |2021.8.22|C XML Analyzer|1.0|原盘DIY辅助脚本上线，大幅优化过水、肉酱分割过程| -->