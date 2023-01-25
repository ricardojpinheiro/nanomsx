# Milli, a wannabe GNU nano-like text editor for MSX.
Ricardo Jurczyk Pinheiro (ricardojpinheiro@gmail.com)

This editor resembles the [GNU nano editor](https://www.nano-editor.org), using the same look-and-feel and most of the keystrokes. I decided to develop a text editor because I'm tired of using AKID/KID/TED/MPW/whatever in my MSXs, when I need to edit some code or even a batch file. So, think about it when you start complaining with me, asking why I didn't implemented this or that _amazing_ feature that you care about. 

### Disclaimer.
This editor is strongly based on [Qed-Editor](https://texteditors.org/cgi-bin/wiki.pl?Qed-Pascal), a pretty old (1987!) text editor. By the way, there isn't any licenses regarding the Qed-Editor's source code, and I know it isn't PD. But its author is unknown, it's open source and I gave all the credits to her/him. So, don't be a license zealot asking about code licenses which belongs to a software which had been abandoned. But Milli is GPL 3.0.

### Requirements.
A MSX 2 with 128 Kb of VRAM and MSX-DOS 2 (if you use [Nextor](https://github.com/Konamiman/Nextor), it would be great). So it uses 80 columns, but it doesn't use Memory Mapper. And sorry, no MSX 1 and/or MSX-DOS 1 versions in my horizon.

### Some characteristics.
- Open source (GPL 3.0).
- All (badly) written in Turbo Pascal 3.0, using SCREEN 0 with blink tables.
- Text files may have less the 1568 lines of 80 columns each, at maximum. Almost all the MSX 2 VRAM.
- Most of the keystrokes from GNU nano text editor are used in Milli.
- Text-block commands: Mark, copy, move, delete and unhide block.
- Mmmm... You may use it and tell me, lack of ideas.

### Future.
As I may have said, there are a lot of improvements that we can do, in order to use less VRAM memory, speed up the code... Sorry pals, I won't do much more than that. But we can work with two or more files simultaneously... Maybe in the future.

This github page reunites some text editors that I've been working with. Milli is the first of them, but I hope I'll build two other editors, in order to resemble the look and feel of the [joe editor](http://joe-editor.sourceforge.net/) (my favourite Linux text editor) and [DosEDIT, from MS-DOS](https://texteditors.org/cgi-bin/wiki.pl?DosEdit) (an all-time favourite). Of course, it'll be done if I have some spare time.

### Download.
Finally, the download link. [Here it goes](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli.com). If you want to get the source code, [you can find a ZIP file here](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli.zip). I used Qed-Editor as the base editor, but I cannot forget some [Kari Lammassaari (in memorian) libraries](https://manuel.msxnet.org/msx/softw/), like text window, blink and fastwrite routines (there is more, I guess), and [PopolonY2K framework](http://www.popolony2k.com.br/), from which I got some SCREEN 0 and MSX-DOS 2 routines. My greetings to their work.

### History
- [2023-01-24 - v0.8 - BTW, I forgot to place it here!](https://github.com/ricardojpinheiro/nanomsx/releases/tag/v0.8])
- [2022-02-09 - v0.7 - Code polishment](https://github.com/ricardojpinheiro/nanomsx/releases/tag/v0.7)
- [2022-01-20 - v0.5 - Hoorah! Blocks, blocks and blocks!](https://github.com/ricardojpinheiro/nanomsx/releases/tag/v0.5)
- [2021-10-04 - v0.3 - Slower than expected, but...](https://github.com/ricardojpinheiro/nanomsx/releases/tag/v0.3)
- [2021-09-09 - v0.2 - Die, nasty bug!](https://github.com/ricardojpinheiro/nanomsx/releases/tag/v0.2)
- [2021-09-02 - v0.1 - First public release](https://github.com/ricardojpinheiro/nanomsx/releases/tag/v0.1)

### Do you wanna test it?
Yes we can. There is a DSK file (download [here](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli.dsk}), but you can runt it with WebMSX. Just click [here](https://webmsx.org?M=MSXTRJ&DISK=https://github.com/ricardojpinheiro/nanomsx/blob/main/milli.dsk?raw=true). BTW, WebMSX is set to a Japanese MSX Turbo-R (is there any other Turbo-R which aren't Japanese? 🤔) in order to have MSX-DOS 2 support.

### Screenshots.
We all love screenshots! Who doesn't? Here it goes some of them:
- [Milli's main screen](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli_ma.png)
- [Milli's help page](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli_he.png)
- [Milli's command line help (/h)](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli_co.png)
- [Milli's command line version (/v)](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli_ve.png)

### Why 'milli'?
The name may come from two places:
1. A unit prefix in the metric system denoting a factor of _one thousandth_. Yeah, like _nano_,but a little bigger. 
2. The restaurant at the end of the Universe, called [Milliways](https://hitchhikers.fandom.com/wiki/Milliways), from the [Hitchhiker''s Guide to the Galaxy](https://hitchhikers.fandom.com/wiki/Main_Page) book series, written by Douglas Adams. **Personally, I would prefer that last one**. 

### Final remark.
Remember that I created this text editor so I could fix my problems regarding text-editing in a MSX. And I hope it helps you too. I'm not a developer myself, I'm a maths professor who writes code for MSX for fun. There are a lot of improvements that I can imagine for milli, but maybe I won´t do it, because my lack of time and more projects to go. So, if you want to improve milli, be my guest, fork it and do your best. I'll be glad to see that my work inspired you to work with my editors.
