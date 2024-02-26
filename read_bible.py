
import json
import os
from pathlib import Path
import torch
from TTS.api import TTS

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

NEW_TESTAMENT_STRUCTURE = [
    {"name": "matthew", "start": 108570, "end": 112497},
    {"name": "mark", "start": 112497, "end": 114775},
    {"name": "luke", "start": 114775, "end": 118719},
    {"name": "john", "start": 118719, "end": 121727},
    {"name": "acts", "start": 121727, "end": 125366},
    {"name": "romans", "start": 125366, "end": 127120},
    {"name": "corinthians_1", "start": 127120, "end": 128754},
    {"name": "corinthians_2", "start": 128754, "end": 129721},
    {"name": "galatians", "start": 129721, "end": 130267},
    {"name": "ephesians", "start": 130267, "end": 130809},
    {"name": "philippians", "start": 130809, "end": 131202},
    {"name": "colossians", "start": 131202, "end": 131597},
    {"name": "thessalonians_1", "start": 131597, "end": 131920},
    {"name": "thessalonians_2", "start": 131920, "end": 132120},
    {"name": "timothy_1", "start": 132120, "end": 132556},
    {"name": "timothy_2", "start": 132556, "end": 132864},
    {"name": "titus", "start": 132864, "end": 133043},
    {"name": "philemon", "start": 133043, "end": 133138},
    {"name": "hebrews", "start": 133138, "end": 134329},
    {"name": "james", "start": 134329, "end": 134755},
    {"name": "peter_1", "start": 134755, "end": 135163},
    {"name": "peter_2", "start": 135163, "end": 135436},
    {"name": "john_1", "start": 135436, "end": 135975},
    {"name": "john_2", "start": 135975, "end": 136052},
    {"name": "john_3", "start": 136052, "end": 136124},
    {"name": "jude", "start": 136124, "end": 136293},
    {"name": "revelation", "start": 136293, "end": 138133},
]

os.makedirs(out_path, mode = 0o777, exist_ok = True)

for book in NEW_TESTAMENT_STRUCTURE:
    read_book_path(book["name"], in_path, out_path, speaker, model, vocoder, lang)
