#!/usr/bin/env python3
import spacy
from spacy.cli.download import download
import inflect
import re
import string

import book_contents

p = inflect.engine()

RE_D = re.compile(r'\d+')
def has_digits(string):
    return RE_D.search(string)


def setup_model(model_name: str) -> spacy.language.Language:
    try:
        return spacy.load(model_name)
    except OSError:
        print(f"{model_name} not found, downloading...")
        download(model_name)
        return spacy.load(model_name)

def preprocess_text(text: str) -> str:
    return text.translate(str.maketrans('', '', string.punctuation))

model: str = 'en_core_web_md'
nlp = setup_model(model)

def replace_with_words(match):
    num_text = match.group(0)
    return p.number_to_words(int(num_text))

def convert_numbers_to_words(text: str) -> str:
    # Remove commas since inflect doesn't handle numerials with commands correctly
    return re.sub(RE_D, replace_with_words, text.replace(',', ''))

def compare_strings(text1: str, text2: str) -> float:
    if not has_digits(text1):
        text2 = convert_numbers_to_words(text2)

    text1 = preprocess_text(text1.lower().strip())
    text2 = preprocess_text(text2.lower().strip())
    
    doc1 = nlp(text1)
    doc2 = nlp(text2)
    return doc1.similarity(doc2)

text1 = "Their camels four hundred thirty-five, their asses six thousand seven hundred and twenty."
text2 = " Their camels 435. Their asses 6,720."
similarity = compare_strings(text1, text2)
print(f"Semantic similarity: {similarity:.2f}")
