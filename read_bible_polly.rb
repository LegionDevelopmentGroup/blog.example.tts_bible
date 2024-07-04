
require 'fileutils'
require 'json'
require 'optparse'

require 'aws-sdk-polly'
require 'net/http'
require 'uri'

require_relative 'util.rb'
require_relative 'book_contents.rb'
require_relative 'book_reader.rb'

# limit 5m free
class PollyReader
    def initialize
        @polly = Aws::Polly::Client.new(region: 'us-east-1') # Replace with your desired region
    end

    def read_book(text, ref, model, vocoder, lang, speaker, ext = '.wav')
        # Call tts function with given text

        target_file = "#{File.join(File.dirname(ref), File.basename(ref, '.wav'))}.mp3"

        if !File.file?(target_file)
             response = @polly.synthesize_speech({
              text: text.join(' '),
              output_format: "mp3",
              voice_id: speaker  # You can choose from various voices
            })

            if response.audio_stream
              # Save the MP3 audio data to a local file
              File.open(target_file, "wb") do |file|
                file.write(response.audio_stream.read)
              end
            else
              puts "Failed to generate MP3."
              exit 1
            end
        end
    end
end


skip = true
target = nil # 'kings_3'
in_path = 'data/douay_rheims_'
out_path = 'polly_audio_out/'

speaker = 'Matthew'
max_token_limit = 4500000
tokens_already_used = 0

OptionParser.new do |opt|
  opt.on('--inpath [=INPUT_PATH]') { |o| in_path = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_path = o }
  opt.on('--speaker [=SPEAKER]') { |o| speaker = o }
  opt.on('--target [=TARGET]') { |o| target = o }
  opt.on('--used_tokens [=USED_TOKENS]', { |o| tokens_already_used = o })
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = false if target.nil?

book_reader = BookReader.new(PollyReader.new, max_token_limit, tokens_already_used)

BIBLE_STRUCTURE.each do |book|
    skip = false if book[:name] == target
    next if skip
    puts "Book: #{book[:name]}"
    book_reader.read_book_path(book[:name], in_path, out_path, speaker, '', '', '')
end