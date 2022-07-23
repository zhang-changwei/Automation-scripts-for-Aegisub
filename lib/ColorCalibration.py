# version 1.1

import tkinter as tk
import tkinter.filedialog as filedialog
import tkinter.messagebox as messagebox
import tkinter.ttk as ttk
from PIL import Image
import numpy as np
import colour
import os

class App:

    def __init__(self):
        self.root = tk.Tk()
        self.root.title('Color Calibration')

        self.files = ()
        self.sdr = ''
        self.hdr = ''
        self.param = tk.IntVar(value=30)

        grid1 = ttk.Labelframe(self.root, text='Convert')
        grid1.pack(side='top', fill='x', padx=10, pady=(10, 5))
        grid2 = ttk.Labelframe(self.root, text='Compare')
        grid2.pack(side='top', fill='x', padx=10, pady=(5, 5))
        grid3 = ttk.Labelframe(self.root, text='Parameter')
        grid3.pack(side='top', fill='x', padx=10, pady=(5, 10))

        ttk.Button(grid1, text='Select', width=15, command=self.selectFiles) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Button(grid1, text='Run', width=15, command=self.convert) \
            .pack(side='left', fill='y', padx=4, pady=4)

        ttk.Button(grid2, text='SDR', width=15, command=lambda x='SDR': self.selectFile(x)) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Button(grid2, text='HDR', width=15, command=lambda x='HDR': self.selectFile(x)) \
            .pack(side='left', fill='y', padx=4, pady=4)
        ttk.Button(grid2, text='Run', width=15, command=self.compare) \
            .pack(side='left', fill='y', padx=4, pady=4)

        ttk.Entry(grid3, textvariable=self.param).pack(fill='both', padx=4, pady=4)

        self.root.mainloop()

    def selectFiles(self):
        path = filedialog.askopenfilenames(title='Select', filetypes=[('PNG File', ['.png', '.PNG'])])
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

    def convert(self):
        if self.files:
            for file in self.files:
                try:
                    im = Image.open(file)
                    arr = np.asarray(im)
                    channel = np.size(arr, axis=-1)
                    if channel == 4:
                        rgb = arr[..., :3]
                        a = arr[..., -1:]
                    else:
                        rgb = arr
                    rgb = self.main(rgb).astype(np.uint8)
                    if channel == 4:
                        arr = np.dstack((rgb, a))
                        im = Image.fromarray(arr, mode='RGBA')
                    else:
                        arr = rgb
                        im = Image.fromarray(arr, mode='RGB')
                    head, tail = os.path.split(file)
                    im.save(os.path.join(head, 'HDR_' + tail))
                except:
                    print(f'An error occured when converting "{file}".')
            messagebox.showinfo(message='Convertion finished.')

    def compare(self):
        if self.sdr and self.hdr:
            try:
                sdr = Image.open(self.sdr)
                hdr = Image.open(self.hdr)
                sdrrgb = np.asarray(sdr)[..., :3]
                hdrrgb = np.asarray(hdr)[..., :3]
                sdrrgb = self.main(sdrrgb)
                err = np.abs(sdrrgb - hdrrgb)
                im = Image.fromarray(err.astype(np.uint8))
                im.show()
            except:
                print(f'An error occured when comparing "{self.sdr}" with "{self.hdr}".')

    def main(self, rgb:np.ndarray):
        rgb = colour.models.eotf_sRGB(rgb / 255)
        rgb = colour.models.RGB_to_RGB(rgb, 
                                        colour.models.RGB_COLOURSPACE_BT709, 
                                        colour.models.RGB_COLOURSPACE_BT2020,
                                        chromatic_adaptation_transform='XYZ Scaling')
        rgb = colour.models.oetf_PQ_BT2100(rgb / self.param.get())
        rgb = colour.models.RGB_to_YCbCr(rgb, colour.WEIGHTS_YCBCR['ITU-R BT.2020'])
        rgb = colour.models.YCbCr_to_RGB(rgb, colour.WEIGHTS_YCBCR['ITU-R BT.709'])
        rgb *= 255
        return rgb

if __name__ == '__main__':
    App()