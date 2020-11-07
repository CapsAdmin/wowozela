import ffmpeg
import sys
import time
import os
import os.path
file_paths = sys.argv[1:]

for p in file_paths:
    name = os.path.basename(p)
    name = os.path.splitext(name)[0]
    stream = ffmpeg.input(p)
    stream = ffmpeg.output(stream, name + "_Output.ogg",  acodec="libvorbis", audio_bitrate="80k")
    ffmpeg.run(stream)

time.sleep(7)
