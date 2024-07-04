import string
import spacy
from metaphone import doublemetaphone

import inflect
import re

RE_D = re.compile(r'\d+')
p = inflect.engine()

def has_digits(string):
    return RE_D.search(string)

def replace_with_words(match):
    num_text = match.group(0)
    return p.number_to_words(int(num_text))

def convert_numbers_to_words(text: str) -> str:
    # Remove commas since inflect doesn't handle numerials with commands correctly
    return re.sub(RE_D, replace_with_words, text.replace(',', ''))

def preprocess_text(text: str) -> str:
    return text.translate(str.maketrans('', '', string.punctuation))

def phonetic_similarity(text1: str, text2: str) -> float:
    nlp = spacy.blank("en")
    
    # Only convert text2 (whisper transcript) if original text doesn't contain any digits.
    # This is to handle book titles and chapter intros which will have digits in the source text.
    # This may miss a case where the source text has both numerials and number text.
    if not has_digits(text1):
        text2 = convert_numbers_to_words(text2)
    
    text1 = preprocess_text(text1.lower().strip())
    text2 = preprocess_text(text2.lower().strip())
    
    print(text1)
    print(text2)
    
    doc1 = nlp(text1)
    doc2 = nlp(text2)
    
    codes1 = {doublemetaphone(token.text)[0] for token in doc1 if doublemetaphone(token.text)[0]}
    codes2 = {doublemetaphone(token.text)[0] for token in doc2 if doublemetaphone(token.text)[0]}
    
    intersection = codes1 & codes2
    union = codes1 | codes2
    print(codes1)
    print(codes2)
    
    print(intersection)
    print(union)
    return len(intersection) / len(union) if union else 1.0


# Example usage
text1 = "Their camels four hundred thirty-five, their asses six thousand seven hundred and twenty."
text2 = " Their camels 435. Their asses 6,720."
similarity = phonetic_similarity(text1, text2)
print(f"Phonetic similarity: {similarity:.2f}")
