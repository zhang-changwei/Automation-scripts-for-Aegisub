# version 1.4

import tkinter as tk
import tkinter.filedialog as filedialog
import tkinter.messagebox as messagebox
import tkinter.ttk as ttk
from PIL import Image
import numpy as np
import colour
import os
import multiprocessing
from timeit import default_timer

def main(file:str, x:str, scaling:float, i8:bool, o8:bool):
    print(f'Processing {file}.')
    try:
        im = Image.open(file)
        if i8:
            im = im.convert('RGBA')
        # to numpy
        arr = np.asarray(im)
        channel = np.size(arr, axis=-1)
        if channel == 4:
            rgb = arr[..., :3]
            a = arr[..., -1:]
        else:
            rgb = arr
        # main function
        if x == 'S2H':
            rgb = sdr2hdr(rgb, scaling).astype(np.uint8)
        else:
            rgb = hdr2sdr(rgb, scaling).astype(np.uint8)
        # to Image
        if channel == 4:
            arr = np.dstack((rgb, a))
            im = Image.fromarray(arr, mode='RGBA')
        else:
            arr = rgb
            im = Image.fromarray(arr, mode='RGB')
        if o8:
            im = im.convert('P')
        # save
        head, tail = os.path.split(file)
        if x == 'S2H':
            im.save(os.path.join(head, 'HDR_' + tail))
        else:
            im.save(os.path.join(head, 'SDR_' + tail))
    except:
        print(f'An error occured when converting "{file}".')

def sdr2hdr(rgb:np.ndarray, scaling:float):
    rgb = colour.models.eotf_sRGB(rgb / 255)
    # rgb = colour.models.oetf_inverse_BT709(rgb / 255)
    # XYZ = colour.models.RGB_to_XYZ(rgb, 
    #                                 colour.models.RGB_COLOURSPACE_sRGB.whitepoint,
    #                                 colour.models.RGB_COLOURSPACE_sRGB.whitepoint,
    #                                 colour.models.RGB_COLOURSPACE_sRGB.matrix_RGB_to_XYZ,
    #                                 chromatic_adaptation_transform='XYZ Scaling')
    # xyY = colour.models.XYZ_to_xyY(XYZ + np.PZERO)
    # xyY[..., -1] = xyY[..., -1] / scaling
    # XYZ = colour.models.xyY_to_XYZ(xyY)
    # rgb = colour.models.XYZ_to_RGB(XYZ,
    #                                 colour.models.RGB_COLOURSPACE_sRGB.whitepoint,
    #                                 colour.models.RGB_COLOURSPACE_BT2020.whitepoint,
    #                                 colour.models.RGB_COLOURSPACE_BT2020.matrix_XYZ_to_RGB,
    #                                 chromatic_adaptation_transform='XYZ Scaling')
    # rgb = colour.models.oetf_PQ_BT2100(rgb)
    rgb = colour.models.RGB_to_RGB(rgb, 
                                    colour.models.RGB_COLOURSPACE_sRGB, 
                                    colour.models.RGB_COLOURSPACE_BT2020,
                                    chromatic_adaptation_transform='XYZ Scaling')
    rgb = colour.models.oetf_PQ_BT2100(rgb / scaling)
    rgb = colour.models.RGB_to_YCbCr(rgb, colour.WEIGHTS_YCBCR['ITU-R BT.2020'])
    rgb = colour.models.YCbCr_to_RGB(rgb, colour.WEIGHTS_YCBCR['ITU-R BT.709'])
    rgb *= 255
    return rgb
def hdr2sdr(rgb:np.ndarray, scaling:float):
    rgb = colour.models.RGB_to_YCbCr(rgb / 255, colour.WEIGHTS_YCBCR['ITU-R BT.709'])
    rgb = colour.models.YCbCr_to_RGB(rgb, colour.WEIGHTS_YCBCR['ITU-R BT.2020'])
    np.putmask(rgb, rgb>1, 1)
    np.putmask(rgb, rgb<0, 0)
    rgb = colour.models.oetf_inverse_PQ_BT2100(rgb)
    rgb *= scaling
    np.putmask(rgb, rgb>1, 1)
    np.putmask(rgb, rgb<0, 0)
    rgb = colour.models.RGB_to_RGB(rgb, 
                                    colour.models.RGB_COLOURSPACE_BT2020, 
                                    colour.models.RGB_COLOURSPACE_sRGB,
                                    chromatic_adaptation_transform='XYZ Scaling')
    np.putmask(rgb, rgb>1, 1)
    np.putmask(rgb, rgb<0, 0)
    rgb = colour.models.eotf_inverse_sRGB(rgb)
    rgb *= 255
    return rgb

class App:

    def __init__(self):
        self.root = tk.Tk()
        self.root.title('Color Calibration')

        self.files = ()
        self.sdr = ''
        self.hdr = ''
        self.param = tk.IntVar(value=30)
        self.cpu = min(8, multiprocessing.cpu_count())

        grid1 = ttk.Labelframe(self.root, text='Convert')
        grid1.pack(side='top', fill='x', padx=10, pady=(10, 5))
        grid2 = ttk.Labelframe(self.root, text='Compare')
        grid2.pack(side='top', fill='x', padx=10, pady=(5, 5))
        grid3 = ttk.Labelframe(self.root, text='Parameter')
        grid3.pack(side='top', fill='x', padx=10, pady=(5, 10))

        ttk.Button(grid1, text='Select', width=15, command=self.selectFiles) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Button(grid1, text='SDR -> HDR', width=15, command=lambda x='S2H': self.convert(x)) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Button(grid1, text='HDR -> SDR', width=15, command=lambda x='H2S': self.convert(x)) \
            .pack(side='left', fill='y', padx=4, pady=4)

        ttk.Button(grid2, text='SDR', width=15, command=lambda x='SDR': self.selectFile(x)) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Button(grid2, text='HDR', width=15, command=lambda x='HDR': self.selectFile(x)) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Button(grid2, text='Run', width=15, command=self.compare) \
            .pack(side='left', fill='y', padx=4, pady=4)

        ttk.Entry(grid3, textvariable=self.param).pack(fill='x', padx=4, pady=4)

        self.inputPNG8 = tk.BooleanVar(value=False)
        self.outputPNG8 = tk.BooleanVar(value=False)
        ttk.Checkbutton(grid3, text='Input PNG8', variable=self.inputPNG8, width=22) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Checkbutton(grid3, text='Output PNG8', variable=self.outputPNG8, width=22) \
            .pack(side='left', fill='y', padx=4, pady=4)

        self.root.mainloop()

    def selectFiles(self):
        path = filedialog.askopenfilenames(title='Select', filetypes=[('PNG File', ['.png', '.PNG', '.jpg'])])
        if path:
            self.files = path
            print(f'Select: {path}')

    def selectFile(self, x):
        path = filedialog.askopenfilename(filetypes=[('PNG File', ['.png', '.PNG', '.*'])])
        if path:
            if x == 'SDR':
                self.sdr = path
                print(f'SDR: {path}')
            elif x == 'HDR':
                self.hdr = path
                print(f'HDR: {path}')

    def convert(self, x:str):
        if self.files:
            t1 = default_timer()
            with multiprocessing.Pool(processes=self.cpu) as pool:
                for file in self.files:
                    pool.apply_async(main, (file, x, self.param.get(), self.inputPNG8.get(), self.outputPNG8.get()))
                    # main(file, x, self.param.get(), self.inputPNG8.get(), self.outputPNG8.get())
                pool.close()
                pool.join()
            t2 = default_timer()
            messagebox.showinfo(message=f'Convertion finished. Used Time {t2-t1}')

    def compare(self):
        if self.sdr and self.hdr:
            try:
                sdr = Image.open(self.sdr)
                hdr = Image.open(self.hdr)
                if self.inputPNG8.get():
                    sdr = sdr.convert('RGBA')
                    hdr = hdr.convert('RGBA')
                sdrrgb = np.asarray(sdr)[..., :3]
                hdrrgb = np.asarray(hdr)[..., :3]
                sdrrgb = self.sdr2hdr(sdrrgb)
                err = np.abs(sdrrgb - hdrrgb)
                im = Image.fromarray(err.astype(np.uint8))
                im.show()
            except:
                print(f'An error occured when comparing "{self.sdr}" with "{self.hdr}".')  

if __name__ == '__main__':
    multiprocessing.freeze_support()
    App()