
import json
import os
from pathlib import Path
import torch
from TTS.api import TTS

import book_contents

# Get device
device = "cuda" if torch.cuda.is_available() else "cpu"

# List available 🐸TTS models
# print(TTS().list_models())

# Init TTS
model = "tts_models/multilingual/multi-dataset/xtts_v2"
tts = TTS(model).to(device)

def read_book(text, ref, model, vocoder, lang, speaker, ext = ".wav"):
    # Text to speech to a file
    my_file = Path(ref)
    if not my_file.exists() and len(text) > 0:
        tts.tts_to_file(text=(" ".join(text)), 
            speaker=speaker,
            language=lang,
            file_path=ref)

def read_book_path(book_name,
    in_folder_path,
    out_folder_path,
    speaker,
    model,
    vocoder,
    lang):
    #book_name = "genesis"
    infile = in_folder_path + book_name + ".json"
    out_folder = out_folder_path + book_name

    file = open(infile)
    book = json.load(file)
    file.close()

    os.makedirs(out_folder, mode = 0o777, exist_ok = True)

    print("Title")
    # Read book["title"], #{out_folder}/title
    read_book(book["title"], "{}/title.wav".format(out_folder), model, vocoder, lang, speaker)

    print("Intro")
    # Read book["intro"], #{out_folder}/intro
    read_book(book["intro"], "{}/intro.wav".format(out_folder), model, vocoder, lang, speaker)

    for index, content in enumerate(book["contents"]):

        print("Chapter {} / {}".format(index + 1, len(book["contents"])))

        os.makedirs("{}/ch_{}".format(out_folder, index+1), mode = 0o777, exist_ok = True)

        # Read content["title"], #{out_folder}/ch_#{index+1}/title
        read_book(content["title"], "{}/ch_{}/title.wav".format(out_folder, index+1), model, vocoder, lang, speaker)

        # Read content["intro"], #{out_folder}/ch_#{content["title"]}/intro
        read_book(content["intro"], "{}/ch_{}/intro.wav".format(out_folder, index+1), model, vocoder, lang, speaker)

        for k, verses in content["contents"].items():
            # Read verses, #{out_folder}/ch_#{content["title"]}/verse_#{k}
            print("Verse {}/{}".format(k, len(content["contents"])))
            read_book(verses, "{}/ch_{}/verse_{}.wav".format(out_folder, index+1, k), model, vocoder, lang, speaker)


in_path = "data/douay_rheims_"
out_path = "audio_out/"

speaker = "Craig Gutsy"

# Unused
vocoder = "vocoder_models/universal/libri-tts/wavegrad"
lang = "en"

os.makedirs(out_path, mode = 0o777, exist_ok = True)

for book in book_contents.NEW_TESTAMENT_STRUCTURE:
    read_book_path(book["name"], in_path, out_path, speaker, model, vocoder, lang)
