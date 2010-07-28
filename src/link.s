ram{start=$000,end=$1C0}
ram{start=$200,end=$800}
copy{file=ines.hdr}
# Bank 0
bank{size=$4000,origin=$8000}
link{file=build/ocean.o}
link{file=build/oceantargets.o}
link{file=build/title.o}
link{file=build/titletheme.o}
# Bank 1
bank{size=$4000,origin=$8000}
link{file=build/count.o}
link{file=build/counttargets.o}
# Bank 2
bank{size=$4000,origin=$8000}
link{file=build/ripepray.o}
link{file=build/ripetargets.o}
# Bank 3
bank{size=$4000,origin=$8000}
link{file=build/break.o}
link{file=build/breaktargets.o}
# Bank 4
bank{size=$4000,origin=$8000}
link{file=build/levva.o}
link{file=build/levvatargets.o}
# Bank 5
bank{size=$4000,origin=$8000}
link{file=build/burn.o}
link{file=build/burntargets.o}
link{file=build/songselectdata.o}
link{file=build/gameuidata.o}
# Bank 6
bank{size=$4000,origin=$8000}
link{file=build/gameselect.o}
link{file=build/challenges.o}
link{file=build/gameinfo.o}
link{file=build/gamestats.o}
link{file=build/gameover.o}
link{file=build/creditwin.o}
link{file=build/piecewin.o}
link{file=build/versuswin.o}
link{file=build/starfield.o}
link{file=build/parallax.o}
link{file=build/cutscene.o}
link{file=build/theend.o}
link{file=build/piecewintheme.o}
link{file=build/creditwintheme.o}
link{file=build/versuswintheme.o}
link{file=build/spacetheme.o}
link{file=build/smooth.o}
# Bank 7
bank{size=$4000,origin=$C000}
link{file=build/fade.o}
link{file=build/palette.o}
link{file=build/sprite.o}
link{file=build/tablecall.o}
link{file=build/ppu.o}
link{file=build/ppuwrite.o}
link{file=build/ppubuffer.o}
link{file=build/joypad.o}
link{file=build/timer.o}
link{file=build/irq.o}
link{file=build/nmi.o}
link{file=build/reset.o}
link{file=build/bitmasktable.o}
link{file=build/multiply.o}
# sound
link{file=build/sfx.o}
link{file=build/periodtable.o}
link{file=build/volumetable.o}
link{file=build/envelope.o}
link{file=build/effect.o}
link{file=build/tonal.o}
link{file=build/dmc.o}
link{file=build/mixer.o}
link{file=build/sequencer.o}
link{file=build/sound.o}
#
link{file=build/mmc3.o}
link{file=build/songselect.o}
link{file=build/ampdisplay.o}
link{file=build/game.o}
link{file=build/targetdatatable.o}
link{file=build/main.o}
link{file=build/sfxdata.o}
link{file=build/songtable.o}
#
link{file=build/misery.o}
link{file=build/mutesong.o}
link{file=build/elevatortheme.o}
link{file=build/starstheme.o}
link{file=build/endtheme.o}
#
pad{origin=$FB20}
link{file=build/dmcdata.o}
pad{origin=$FFFA}
link{file=build/vectors.o}
# CHR banks
bank{size=$20000}
copy{file=graphics/title-bg.chr}         # 0
copy{file=graphics/title-spr.chr}        # 4
copy{file=graphics/songselect-bg.chr}    # 8
copy{file=graphics/songselect-spr.chr}   # 12
copy{file=graphics/game.chr}             # 16
copy{file=graphics/gameselect-bg.chr}    # 24
copy{file=graphics/challenges-bg.chr}    # 28
copy{file=graphics/cutscene.chr}         # 32
copy{file=graphics/completedpad.chr}     # 34
copy{file=graphics/magazine-bg.chr}      # 36
copy{file=graphics/guitar-fender-8x8.chr} # 40
copy{file=graphics/guitar-lespaul-8x8.chr} # 41
copy{file=graphics/guitar-vortex-8x8.chr} # 42
copy{file=graphics/paperfont.chr}        # 43
copy{file=graphics/rockface-spr.chr}     # 44
copy{file=graphics/kentando-bg.chr}      # 48
pad{origin=$20000}
