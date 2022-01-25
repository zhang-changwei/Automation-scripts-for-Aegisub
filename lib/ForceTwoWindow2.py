from PIL import Image
import re
# version 1.5.2
# parser.add_argument("-i","--input", type=str, nargs="+")
# parser.add_argument("-o","--output", type=str, nargs="+")
# parser.add_argument("-m","--mode", type=int, default=0, help="0: crop and convert, 1: merge, 2: convert only")
# parser.add_argument("-c","--crop", type=int, nargs="+")
# parser.add_argument("-u","--unite",type=int, nargs=6, help="x,y,posx1,posy1,posx2,posy2")

batPath = 'forcetwowindow.bat'
file = open(batPath, 'r')

inputpathList, outputpathList, cropsList, uList, modeList = [],[],[],[],[]

for node in file.readlines():
    inputpath, outputpath, crops, u = [],[],[],[]
    mode = 0
    node = node.strip()
    if re.match('start cmd', node)!=None:
        inputStr = re.search('-i (.+?) -', node).group(1)
        inputpath = re.split(' ', inputStr)
        outputStr = re.search('-o (.+?) -', node).group(1)
        outputpath = re.split(' ', outputStr)
        if re.search('-m', node)!=None: 
            mode = int(re.search('-m (\d)', node).group(1))
        if re.search('-c', node)!=None:
            cropStr = re.search('-c (.+?)[-\"]', node).group(1).strip()
            crops = re.split(' ', cropStr)
            crops = list(map(int, crops))
        if re.search('-u', node)!=None:
            uStr = re.search('-u (.+?)[-\"]', node).group(1).strip()
            u = re.split(' ', uStr)
            u = list(map(int, u))
        # print(inputpath, outputpath, mode, crops)
        inputpathList.append(inputpath)
        outputpathList.append(outputpath)
        cropsList.append(crops)
        uList.append(u)
        modeList.append(mode)
    else: continue

file.close()

for inputpath, outputpath, crops, u, mode in zip(inputpathList, outputpathList, cropsList, uList, modeList):
    if mode==2:
        im = Image.open(inputpath[0])
        im = im.convert("P", colors=256)
        im.save(outputpath[0])
    elif mode==0:
        im = Image.open(inputpath[0])
        box1 = (crops[0], crops[1], crops[2], crops[3])
        im1  = im.crop(box1)
        im1  = im1.convert("P", colors=256)
        im1.save(outputpath[0])
        if len(crops)==8:
            box2 = (crops[4], crops[5], crops[6], crops[7])
            im2  = im.crop(box2)
            im2  = im2.convert("P", colors=256)
            im2.save(outputpath[1])
    else: # mode==1
        im1, im2 = Image.open(inputpath[0]), Image.open(inputpath[1])
        box1 = (u[2], u[3])
        box2 = (u[4], u[5])
        canvas = Image.new("RGBA", size=(u[0], u[1]), color=(0,0,0,0))
        canvas.paste(im1, box=box1)
        canvas.paste(im2, box=box2)
        box1 = (crops[0], crops[1], crops[2], crops[3])
        im1  = canvas.crop(box1)
        im1  = im1.convert("P", colors=256)
        im1.save(outputpath[0])
        if len(crops)==8:
            box2 = (crops[4], crops[5], crops[6], crops[7])
            im2  = canvas.crop(box2)
            im2  = im2.convert("P", colors=256)
            im2.save(outputpath[1])