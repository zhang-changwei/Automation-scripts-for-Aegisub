from xml.etree.ElementTree import ElementTree
from PIL import Image, ImageDraw
import re
import xml.etree.ElementTree as ET
# version 1.6
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

if __name__ == '__main__':
    xml = ET.parse('ForcedWindow.conf')
    root = xml.getroot()
    count = len(root)
    ind = 1
    for outNode in root:
        for inNode in outNode:
            if int(inNode.attrib['X']) <= int(outNode.attrib['X']) \
                and int(inNode.attrib['Y']) <= int(outNode.attrib['Y']) \
                and int(inNode.attrib['X']) + int(inNode.attrib['Width']) >= int(outNode.attrib['X']) + int(outNode.attrib['Width']) \
                and int(inNode.attrib['Y']) + int(inNode.attrib['Height']) >= int(outNode.attrib['Y']) + int(outNode.attrib['Height']):
                # only crop
                l = int(outNode.attrib['X']) - int(inNode.attrib['X'])
                t = int(outNode.attrib['Y']) - int(inNode.attrib['Y'])
                r = l + int(outNode.attrib['Width'])
                b = t + int(outNode.attrib['Height'])

                im = Image.open(inNode.attrib['Name'])
                im = im.crop((l, t, r, b))

                palette = Palette(im)
                color = palette.setColor()
                im = addBorder(im, color)
                im.putpalette(palette.palette, 'RGBA')

                im.save(outNode.attrib['Name'])
                break
        else:
            # merge and crop
            canvas = Image.new('RGBA', size=(1920, 1080), color=(0, 0, 0, 0))
            box = (int(outNode.attrib['X']), int(outNode.attrib['Y']), 
                int(outNode.attrib['X']) + int(outNode.attrib['Width']), int(outNode.attrib['Y']) + int(outNode.attrib['Height']))
            for inNode in outNode:
                boxIn = (int(inNode.attrib['X']), int(inNode.attrib['Y']), 
                    int(inNode.attrib['X']) + int(inNode.attrib['Width']), int(inNode.attrib['Y']) + int(inNode.attrib['Height']))
                im = Image.open(inNode.attrib['Name'])
                im = im.convert('RGBA')
                canvas.paste(im, boxIn)
            canvas = canvas.convert('P', colors=256)
            im = canvas.crop(box)

            palette = Palette(im)
            color = palette.setColor()
            im = addBorder(im, color)
            im.putpalette(palette.palette, 'RGBA')

            im.save(outNode.attrib['Name'])
        print('Processing: {}/{}'.format(ind, count))
        ind += 1