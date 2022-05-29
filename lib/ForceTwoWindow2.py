from PIL import Image, ImageDraw
import re
# version 1.5.5
# parser.add_argument("-i","--input", type=str, nargs="+")
# parser.add_argument("-o","--output", type=str, nargs="+")
# parser.add_argument("-m","--mode", type=int, default=0, help="0: crop and convert, 1: merge, 2: convert only")
# parser.add_argument("-c","--crop", type=int, nargs="+")
# parser.add_argument("-u","--unite",type=int, nargs=6, help="x,y,posx1,posy1,posx2,posy2")
# I have to use pillow 8.2.0 here, they may change the api of palette, it leads to some wired problem.

class Palette:
    
    def __init__(self, im:Image.Image):
        imRGBA = im.convert('RGBA')

        pix = im.load()
        pixRGBA = imRGBA.load()

        colors = {}
        self.leastSignificantEntry = [None, 255]
        for w in range(im.width):
            for h in range(im.height):
                if pix[w, h] not in colors.keys():
                    i, c = pix[w, h], pixRGBA[w, h]
                    colors[i] = c
                    if c[-1] > 0 and c[-1] < self.leastSignificantEntry[1]:
                        self.leastSignificantEntry = [i, c[-1]]

        self.palette = []
        self.emptyEntry = []
        for i in range(256):
            if i in colors.keys():
                self.palette.extend(colors[i])
            else:
                self.emptyEntry.append(i)
                self.palette.extend((0, 0, 0, 0))
    
    def setColor(self, color=(0, 0, 0, 2)) -> int:
        if self.emptyEntry:
            ind = self.emptyEntry[0]
            self.palette[ind*4: ind*4 + 4] = color
            self.emptyEntry.pop(0)
            return ind
        elif self.leastSignificantEntry[0]:
            ind = self.leastSignificantEntry[0]
            self.palette[ind*4: ind*4 + 4] = color
            self.leastSignificantEntry = [None, 255]
        else:
            raise ValueError('Not enough entry')

def addBorder(im:Image.Image, color):
    rect = ImageDraw.Draw(im)
    rect.rectangle([(0, 0), (im.width-1, im.height-1)], outline=color, width=1)
    return im

def openConfig(fp='ForceTwoWindow2.conf'):
    file = open(fp, 'r')

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

    return inputpathList, outputpathList, cropsList, uList, modeList

if __name__ == '__main__':
    inputpathList, outputpathList, cropsList, uList, modeList = openConfig('ForceTwoWindow2.conf')

    length = len(modeList)
    for i, inputpath, outputpath, crops, u, mode in zip(range(length), inputpathList, outputpathList, cropsList, uList, modeList):
        if mode==2:
            im = Image.open(inputpath[0])
            im = im.convert("P", colors=256)
            im.save(outputpath[0])
        elif mode==0: # crop and convert
            im = Image.open(inputpath[0])
            box1 = (crops[0], crops[1], crops[2], crops[3])
            im1 = im.crop(box1)

            palette = Palette(im1)
            color = palette.setColor()
            im1 = addBorder(im1, color)
            im1.putpalette(palette.palette, 'RGBA')

            im1.save(outputpath[0])
            if len(crops)==8:
                box2 = (crops[4], crops[5], crops[6], crops[7])
                im2  = im.crop(box2)

                palette = Palette(im2)
                color = palette.setColor()
                im2 = addBorder(im2, color)
                im2.putpalette(palette.palette, 'RGBA')

                im2.save(outputpath[1])
        else: # mode==1 merge
            im1, im2 = Image.open(inputpath[0]), Image.open(inputpath[1])
            box1 = (u[2], u[3])
            box2 = (u[4], u[5])
            im1 = im1.convert('RGBA')
            im2 = im2.convert('RGBA')
            canvas = Image.new('RGBA', size=(u[0], u[1]), color=(0, 0, 0, 0))
            canvas.paste(im1, box=box1)
            canvas.paste(im2, box=box2)
            canvas = canvas.convert('P', colors=256)

            box1 = (crops[0], crops[1], crops[2], crops[3])
            im1  = canvas.crop(box1)
            
            palette = Palette(im1)
            color = palette.setColor()
            im1 = addBorder(im1, color)
            im1.putpalette(palette.palette, 'RGBA')

            im1.save(outputpath[0])
            if len(crops)==8:
                box2 = (crops[4], crops[5], crops[6], crops[7])
                im2  = canvas.crop(box2)
                
                palette = Palette(im2)
                color = palette.setColor()
                im2 = addBorder(im2, color)
                im2.putpalette(palette.palette, 'RGBA')

                im2.save(outputpath[1])
        print('Processing: {}/{}'.format(i+1, length))