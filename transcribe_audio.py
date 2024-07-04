
import json
import os
from pathlib import Path

import torch
import whisper
from whisper.utils import get_writer

import book_contents

device = "cuda" if torch.cuda.is_available() else "cpu"

model = whisper.load_model("base", device)

def read_book(text, ref, out_transript, lang, ext = ".wav"):
    # Text to speech to a file
    my_file = Path(ref)
    if not my_file.exists() and len(text) > 0:
        result = model.transcribe(ref, language = lang)
        writer = get_writer("json", out_transript) # Update out dir
        writer(result, ref, None)


def read_book_path(book_name,
    in_folder_path,
    audio_folder_path,
    transcribe_folder_path,
    lang):
    #book_name = "genesis"
    infile = in_folder_path + book_name + ".json"
    audio_folder = audio_folder_path + book_name
    transcribe_folder = transcribe_folder_path + book_name

    file = open(infile)
    book = json.load(file)
    file.close()

    os.makedirs(audio_folder, mode = 0o777, exist_ok = True)

    print("Title")
    # Read book["title"], #{audio_folder}/title
    read_book(book["title"], "{}/title.wav".format(audio_folder), transcribe_folder, lang)

    print("Intro")
    # Read book["intro"], #{audio_folder}/intro
    read_book(book["intro"], "{}/intro.wav".format(audio_folder), transcribe_folder, lang)

    for index, content in enumerate(book["contents"]):

        print("Chapter {} / {}".format(index + 1, len(book["contents"])))

        os.makedirs("{}/ch_{}".format(audio_folder, index+1), mode = 0o777, exist_ok = True)

        # Read content["title"], #{audio_folder}/ch_#{index+1}/title
        read_book(content["title"], "{}/ch_{}/title.wav".format(audio_folder, index+1), "{}/ch_{}/".format(transcribe_folder, index+1), lang)

        # Read content["intro"], #{audio_folder}/ch_#{content["title"]}/intro
        read_book(content["intro"], "{}/ch_{}/intro.wav".format(audio_folder, index+1), "{}/ch_{}/".format(transcribe_folder, index+1), lang)

        for k, verses in content["contents"].items():
            # Read verses, #{audio_folder}/ch_#{content["title"]}/verse_#{k}
            print("Verse {}/{}".format(k, len(content["contents"])))
            read_book(verses, "{}/ch_{}/verse_{}.wav".format(audio_folder, index+1, k), "{}/ch_{}/".format(transcribe_folder, index+1), lang)


in_path = "data/douay_rheims_"
out_path = "audio_out/"
transcribe_path = ""

# Unused
lang = "en"

os.makedirs(out_path, mode = 0o777, exist_ok = True)

for book in book_contents.NEW_TESTAMENT_STRUCTURE:
    read_book_path(book["name"], in_path, out_path, transcribe_path, lang)
