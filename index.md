# Milli, a wannabe GNU nano-like text editor for MSX.
## by Ricardo Jurczyk Pinheiro (ricardojpinheiro@gmail.com)

This editor resembles the GNU nano editor <https://www.nano-editor.org>, using the same look-and-feel and most of the keystrokes. I decided to develop a text editor because I'm tired of using AKID/KID/TED/MPW/whatever in my MSXs, when I need to edit some code, or even a batch file. So, think about it when you start complaining with me, asking why I didn't implemented this or that amazing feature. 

### Disclaimer.
This editor is strongly based on [Qed-Editor](https://texteditors.org/cgi-bin/wiki.pl?Qed-Pascal), a pretty old (1987!) text editor. By the way, there isn't any licenses regarding the Qed-Editor's source code, and I know it isn't PD. But it's author is unknown, it's open source and I gave all the credits to her/him. So, don't be a license zealot asking about code licenses to a software which is older than GPL 1.0.

This github page reunites some text editors that I've been working with. Milli is the first of them, but I hope I'll build two other edtiors, in order to resemble the look and feel of the [joe editor](http://joe-editor.sourceforge.net/) (my favourite Linux text editor) and [DosEDIT, from MS-DOS](https://texteditors.org/cgi-bin/wiki.pl?DosEdit) (an all-star favourite). Of course, it'll be done if I have some spare time.

### Some characteristics.
- Open source (GPL 3.0). So, you can find the code here.
- All (badly) written in Turbo Pascal 3.0, using SCREEN 0 with blink attributes.
- Text files may have 980 lines of 78 columns each, at maximum.
- Most of the keystrokes from GNU nano text editor, like alignment, search and replace, page down and page up, help (tip: it's F1, or Control-G)...
- Mmmm... You may use it and tell me.

### Requirements.
A MSX 2 with 128 Kb of VRAM and MSX-DOS 2 (if you use Nextor, it would be a must). So it uses 80 columns, but it doesn't use Memory Mapper. And sorry, no MSX 1 and/or MSX-DOS 1 versions in my horizon.

### Future implements.
There are two more features that I want to create for Milli: Some text-block commands (copy, move and remove text-blocks), and line numbering. As I may have said, there are a lot of improvements that we can do, in order to use less VRAM memory, speed up the code... But sorry pals, I won't do even more.  

### Download.
Finally, the download link. [Here it goes](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli.com). If you want to get the source code, [you can find a ZIP file here](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli.zip). I used Qed-Editor as the base editor, but I cannot forget some [Kari Lammassaari (in memorian) libraries](https://manuel.msxnet.org/msx/softw/), like text window, blink and fastwrite routines (there is more, I guess), and [PopolonY2K framework](http://www.popolony2k.com.br/), from which I got some SCREEN 0 and MSX-DOS 2 routines. My greetings to them.

### Screenshots.
We all love screenshots! Who doesn´t? Here it goes some of them:

***
![Main screen](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli%20main%20screen.png)

Milli's main screen.
***
![Help page](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli%20help.png)

Milli's help page.
***
![Command line help](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli%20command%20line%20help.png)

Milli's command line help (/h).
***
![Command line version](https://github.com/ricardojpinheiro/nanomsx/blob/main/milli%20version.png)

Milli's command line version (/v).
***

### Why 'milli'?
The name may come from two places:
1. A unit prefix in the metric system denoting a factor of _one thousandth_.
2. The restaurant at the end of the Universe, called [Milliways](https://hitchhikers.fandom.com/wiki/Milliways), from the [Hitchhiker''s Guide to the Galaxy](https://hitchhikers.fandom.com/wiki/Main_Page) book series, written by Douglas Adams. **Personally, I would prefer that last one**. 

### Final remark.
Remember that I done this editor in order to solve my problems. And I hope it helps you too. But I'm not a developer myself, I'm a maths professor who writes code for MSX, and only for fun. There are a lot of improvements that I can imagine for milli, but maybe I won´t do it, because of my lack of time. So, if you want to improve milli, be my guest, fork it and do your best. I'll be glad to see that my work inspired you to work with my editors.
