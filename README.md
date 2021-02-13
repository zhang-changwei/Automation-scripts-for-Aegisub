# Automation-scripts-for-Aegisub
## 目录
0. __前言__
1. __C Font Resize__
2. __C Gradient__
3. __C Translation__
4. __C Scaling Rotation Conflict Solution__
5. __C Change SUB resolution to match video PATCH__
6. __更新日志__

## 0. 前言
* __当前各脚本版本信息__
    | Name                            | Version |
    |---------------------------------|---------|
    | C Font Resize (Mocha Deshaking) | v1.1    |
    | C Gradient                      | v2.0    |
    | C Translation                   | v3.0    |
    | C Scaling Rotation Conflict Solution | v1.0 |
    | C Change SUB resolution to match video PATCH | v1.0 |
    > 在Automation Manager Description栏中查看脚本版本信息  
    > 若你的脚本在上述表格中且无版本信息 可能需要考虑更新脚本
* __使用方法__
    + 将LUA脚本复制到`C:\Program Files (x86)\Aegisub\automation\autoload`路径下，或你的Aegisub安装位置
    + 在Aegisub Automation项中可以发现添加的脚本

----------------------------------------------------------
## 1. C Font Resize
* __Feature__  
    Mocha 防抖  
* __Usage__  
    在Mocha Apply前使用  
    选中行(多行)运行即可
* __Example__  
    `1  {\fs80\fscx120\fsp1}exam{\fs95\t(\fscx150)}ple`  
    -> After running (assuming default scale_y=100) ->   
    `1  {\fscy1000\fs8\fscx1200\fsp0.100}exam{\fscx1266\fscy1055\fs9\t(\fscx1583)}ple`  
* __Warning__  
    不允许 `\t(fs)` 代码  
    字体中不允许出现 "W"

## 2. C Gradient
* __Feature__  
    对逐行/逐帧字幕，自动填写中间行标签代码，以渐变模式填充  

    对Mocha无法正常追踪的片段，进行手动调整   
    便捷实现反复变色/闪烁效果的标签填充  
    便捷实现彩虹边框/阴影效果  
    More...
* __Usage__   
    选中多行字幕 运行LUA脚本    
    设置 setting,mode,rule,accel 选项     
    根据需求在下拉框中选中所需标签，并勾选相应勾选框   
    若标签被 `\t` 包裹，且需要程序生成 `\t` 起止时间等信息，请勾选 `\t` 勾选框(暂不可用)
* __GUI__
    + __setting:__   
    时间模式和行模式切换，勾选为时间模式，为渐变插值依据。如为相同时间轴字幕实现空间渐变效果，必须选择行模式；如为逐帧字幕实现空间渐变效果，建议选择时间模式。  
    + __accel (float number):__   
    加速度，参数范围 `(0,+∞)` ,当 `accel=1` 时为线性渐变，当 `accel>1` 时为先慢后快的渐变，当 `accel<1` 时为先快后慢的渐变，具体数学形式同 `y=x^a` 在定义域 `(0,1)` 中行为，accel为其中指数因子a。  
    + __mode (exact match/custom):__  
    exact match: 精确匹配模式，选中标签必须在选中字幕的每一行都出现，且位于相同位置(position)(后面会说明)  
    custom：定制模式，选中标签仅需出现在选中字幕的首位行，但仍需处于相同位置(position)  
    + __rule (string):__  
    mode 的规则，书写规则为 `%d%d[ht]?,%d%d[ht]?...` 两个数字和一个字母为一个规则块，以半角逗号分隔  
    每个规则块中首位数字为 tag block number, 第二位数字为 tag position number, 第三位字母为 head or tail, 可略去不写。  
    __tag block number:__   
    `{ tag block 1 } text block 1 { tag block 2 } text block 2 ...`  
    若干一个 text block 前有多个`{}`脚本将自动将其合并  
    行首若缺少 tag block 脚本将自动添加      
    __tag position number:__  
    你欲操作标签在一个 tag block 中所有该标签中的序数  
    `{\fs1(#1)\bord1\t(\shad1\fs2(#2))\fs9(#3)}` accusming the tag you want to manipulate is `\fs`  
    __head or tail:__  
    仅对 custom mode 有效，'h'=head，即添加标签至 tag block 首，'t'=tail，即添加标签至 tag block 尾，若略去不写，默认为 'h'。  
    + __\t__  
    待开发
* __Example__  
    `1 {\c&H0000FF&}example`  
    `2 example`   
    `3 {\c&H00FF00&}example`  
    -> After running (`custom, rule: 11t, accel=1`)  
    `1 {\c&H0000FF&}example`  
    `2 {\c&H008080&}example`   
    `3 {\c&H00FF00&}example`  
* __Warning__  
    一次只能运行对一种 tag 进行操作  
    字体中不允许出现 "W"
    
## 3. C Translation
* __Feature__  
    对逐行/逐帧字幕中的特定标签进行平移(即放大/缩小标签数值)

    对存在整体偏移的Mocha生成行，进行细微调整  
    对字幕进行整体平移，如向下平移一个黑边距离  
    > Tip: 勾选 `posy` 和 `clipy` 标签，将对应 `start` 和 `end` 都设为一个黑边距离，其他参数保持默认即可。

    制作3D特效，整体向右平移960pixel   
    More...
* __Usage__  
    选中多行字幕 运行LUA脚本    
    设置 setting 选项     
    根据需求勾选特效标签勾选框，而后设置对应 start, end, accel, index 数值  
    > 一次可以勾选多个特效标签 这一点与 C Gradient 不同
* __GUI__  
    + __setting:__  
    同 C Font Resize / GUI / setting  
    + __start (float number):__  
    选中行首行选中标签将增大数值
    + __end (float number):__  
    选中行末行选中标签将增大数值  
    + __accel (float number):__  
    同 C Font Resize / GUI / accel
    + __index (int number):__  
    你欲操作标签在该行所有 tag block 中所有该标签中的序数  
    `{\fs1(#1)\bord1\t(\shad1\fs2(#2))} text block 1 {\fs9(#3)} text block 2` accusming the tag you want to manipulate is `\fs`   
* __Example__  
    `1 {\pos(500,500)}example`  
    `2 {\pos(500,500)}example`
    `3 {\pos(500,500)}example`  
    -> After running (`posx: check, start: 100, end: 200, accel=1`)  
    `1 {\pos(600.000,500)}example`  
    `2 {\pos(650.000,500)}example`   
    `3 {\pos(700.000,500)}example`  
* __Warning__  
    不支持 `\t(\clip)` 标签  
    字体中不允许出现 "W"

## 4. C Scaling Rotation Conflict Solution
* __Feature__  
    解决拉伸代码 `\fscx \fscy` 与旋转代码 `\frx fry` 生成SUP时冲突的问题  
    将拉伸代码 `\fscx \fscy` 写入样式表中，并以后缀区分新增样式
* __Usage__  
    选中一行(多行)字幕，运行LUA脚本，设置 suffix 数值即可
* __GUI__  
    suffix (int number):  
    首行新样式名后缀
* __Example__  
    `1 Default {\fscx120\fscy130\frx1\fry2\frz5}example`  
    `2 Default {\fscx130\fscy140\frx2\fry3\frz5}example`  
    `3 Default {\fscx140\fscy150\frx3\fry4\frz5}example`  
    -> After running (`suffix=1`)  
    `1 Default_1 {\frx1\fry2\frz5}example`  
    `2 Default_2 {\frx2\fry3\frz5}example`   
    `3 Default_3 {\frx3\fry4\frz5}example`  
* __Warning__  
    选中每行字幕有且只能有一组拉伸代码
    > 程序会在样式表中产生大量样式，谨慎使用
----------------------------------------------------------------
## 6. 更新日志  
