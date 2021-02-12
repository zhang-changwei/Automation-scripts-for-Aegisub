# Automation-scripts-for-Aegisub
## 目录
0. 前言
1. C Font Resize
2. C Gradient
3. C Translation

## 0. 前言
* 当前各脚本版本信息 
    | Name                            | Version |
    |---------------------------------|---------|
    | C Font Resize (Mocha Deshaking) | v1.1    |
    | C Gradient                      | v2.0    |
    | C Translation                   | v2.0    |
    > 在Automation Manager Description栏中查看脚本版本信息  
    > 若你的脚本在上述表格中且无版本信息 可能需要考虑更新脚本
* 使用方法
    + 将LUA脚本复制到`C:\Program Files (x86)\Aegisub\automation\autoload`路径下，或你的Aegisub安装位置
    + 在Aegisub Automation项中可以发现添加的脚本

    

----------------------------------------------------------
## 1. C Font Resize
* Feature  
    Mocha 防抖  
* Usage  
    在Mocha Apply前使用  
    选中行(多行)运行即可
* Example  
    `1  {\fs80\fscx120\fsp1}exam{\fs95\t(\fscx150)}ple`  
    -> After running (assuming default scale_y=100) ->   
    `1  {\fscy1000\fs8\fscx1200\fsp0.100}exam{\fscx1266\fscy1055\fs9\t(\fscx1583)}ple`  
* Warning  
    不允许 `\t(fs)` 代码  
    字体中不允许出现 "W"
## 2. C Gradient
* Feature  
    对逐行/逐帧字幕，自动填写中间行标签代码，以渐变模式填充  

    对Mocha无法正常追踪的片段，进行手动调整
    便捷实现反复变色/闪烁效果的标签填充  
    便捷实现彩虹边框/阴影效果  
    More...
* Usage   
    选中多行字幕 运行LUA脚本
    设置 setting,mode,rule,accel 选项
    根据需求在下拉框中选中所需标签，并勾选相应勾选框  
    若标签被 `\t` 包裹，且需要程序生成 `\t` 起止时间等信息，请勾选 `\t` 勾选框(暂不可用)
* GUI  
    + setting:   
    时间模式和行模式切换，勾选为时间模式，为渐变插值依据。如为相同时间轴字幕实现空间渐变效果，必须选择行模式；如为逐帧字幕实现空间渐变效果，建议选择时间模式。  
    + accel :  
    加速度，参数范围 `(0,+∞)` ,当 `accel=1` 时为线性渐变，当 `accel>1` 时为先慢后快的渐变，当 `accel<1` 时为先快后慢的渐变，具体数学形式同 `y=x^a` 在定义域 `(0,1)` 中行为 accel为之中指数因子a。  
    + mode (exact match/custom) :  
    exact match: 精确匹配模式，选中标签必须在选中字幕的每一行都出现，且位于相同位置(position)(后面会说明)  
    + custom：定制模式，选中标签仅需出现在选中字幕的首位行，但仍需处于相同位置(position)  
    + rule:  
    mode 的规则，书写规则为 `%d%d[ht]?,%d%d[ht]?...` 两个数字和一个字母为一个规则块，以半角逗号分隔  
    每个规则块中首位数字为 tag block number, 第二位数字为 tag position number, 第三位字母为 head or tail, 可略去不写。  
    tag block number：   
    `{ tag block 1 } text block 1 { tag block 2 } text block 2 ...`  
    若干一个 text block 前有多个`{}`脚本将自动将其合并  
    行首若缺少 tag block 脚本将自动添加      
    tag position number:   
    你欲操作标签在一个 tag block 中所有该标签中的序数  
    `{\fs1(#1)\bord1\t(\shad1\fs2(#2))\fs9(#3)}` accusming the tag you want to manipulate is `\fs`  
    head or tail:
    仅对 custom mode 有效，'h'=head，即添加标签至 tag block 首，'t'=tail，即添加标签至 tag block 尾，若略去不写，默认为 'h'。  
    + \t  
    待开发
* Example  
    `1 {\c&H0000FF&}example`  
    `2 example`   
    `3 {\c&H00FF00&}example`  
    -> After running (`custom, rule: 11t, accel=1`)  
    `1 {\c&H0000FF&}example`  
    `2 {\c&H008080&}example`   
    `3 {\c&H00FF00&}example`  
* Warning  
    一次只能运行对一种 tag 进行操作  
    字体中不允许出现 "W"







