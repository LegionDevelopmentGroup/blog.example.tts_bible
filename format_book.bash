set -e
set -x

# Run entire procedure on targets:

# Location of source code
source_dir=./
# Location of audio files generated using TTS
audio_source_dir=audio/
# Location of parsed book data
data_source_dir=data/douay_rheims_
# Temp folder for copying files and operating on files
tmp_dir=tmp/
# Final output destination for the audio book
output_dir=full_book/
# Target just a specific book by specifying the name. Leave empty to perform the actions for all books. This isn't fully supported and may not work as expected.
target=

ruby "${source_dir}create_chapter_playlist.rb" --audio_inpath ${audio_source_dir} --data_inpath ${data_source_dir} --outpath ${tmp_dir} --target "${target}"

ruby "${source_dir}create_verse_per_chapter.rb" --audio_inpath ${audio_source_dir} --data_inpath ${data_source_dir} --outpath ${tmp_dir} --target "${target}"

ruby "${source_dir}iterate_book.rb" --inpath ${data_source_dir} --outpath ${tmp_dir} --target "${target}"

ruby "${source_dir}create_mka_chapter_playlist.rb" --data_inpath ${data_source_dir} --outpath ${tmp_dir} --target "${target}"

ruby "${source_dir}finalize_book.rb" --data_inpath ${data_source_dir} --tmppath ${tmp_dir} --audio_inpath ${audio_source_dir} --outpath ${output_dir} --target "${target}"
