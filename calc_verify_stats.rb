
require 'fileutils'
require 'json'
require 'optparse'

#require 'levenshtein'

require_relative 'util.rb'
require_relative 'book_contents.rb'

def init_errors_pair
    {
        match_errors: 0,
        timing_errors: 0,
        total_errors: 0,
        total: 0
    }
end

def print_fraction(numerator, denominator)
    "#{numerator} / #{denominator} = #{(numerator.to_f / denominator).round(4)}"
end

def calculate_verify(book_name, verify_in_file, verify_out_file)
    file = File.open("#{verify_in_file}#{book_name}_verify.json")
    verifications = JSON.load(file)

    puts "len #{verifications.size}"

    out_file = "#{verify_out_file}#{book_name}_verify_status.json"

    total_items = 0
    total_match_errors = 0
    total_timing_errors = 0
    total_errors = 0

    section_items = [:title, :intro, :chapter, :chapter_intro, :verse]

    section_totals = {}
    section_items.each do |item|
        section_totals[item] = init_errors_pair
    end

    status = nil

    verifications.each do |verification|

        if verification['path'].include?('ch_')
            status = :chapter if verification['path'].include?('title')
            status = :chapter_intro if verification['path'].include?('intro')
            status = :verse if verification['path'].include?('verse_')
        else
            status = :title if verification['path'].include?('title')
            status = :intro if verification['path'].include?('intro')
        end

        # break if verification['raw_text_nom'] == "genesis chapter 2"
        # next if status != :chapter_intro

        if !verification['text_match']
            total_match_errors += 1

            section_totals[status][:match_errors] += 1
        end

        if verification['timing_issue']
            total_timing_errors += 1

            section_totals[status][:timing_errors] += 1
        end

        if !verification['text_match'] || verification['timing_issue']
            section_totals[status][:total_errors] += 1
            total_errors += 1
        end

        total_items += 1
        section_totals[status][:total] += 1
    end

    puts "Total Items:   #{total_items}"
    puts "match errors:  #{print_fraction(total_match_errors, total_items)}"
    puts "timing errors: #{print_fraction(total_timing_errors, total_items)}"
    puts "total errors:  #{print_fraction(total_errors, total_items)}"

    section_totals.each do |k, item|
        puts "#{k} match errors:  #{print_fraction(item[:match_errors], item[:total])}, #{print_fraction(item[:match_errors], total_items)}"
        puts "#{k} timing errors: #{print_fraction(item[:timing_errors], item[:total])}, #{print_fraction(item[:timing_errors], total_items)}"
        puts "#{k} total errors:  #{print_fraction(item[:total_errors], item[:total])}, #{print_fraction(item[:total_errors], total_items)}"
    end

    fields = {
        total: total_items,
        match_errors: total_match_errors,
        timing_errors: total_timing_errors,
        category_errors: section_totals,
    }
    File.open(out_file, 'w') { |file| file.write(fields.to_json) }
end

skip = true
target = 'exodus' #nil # 'kings_3'
data_in_path = 'verify_files/douay_rheims_'
# audio_in_path = 'audio_out/'
out_path = 'verify_files/douay_rheims_'

OptionParser.new do |opt|
  opt.on('--data_inpath [=DATA_INPUT_PATH]') { |o| data_in_path = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_path = o }
  opt.on('--target [=TARGET]') { |o| target = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = false if target.nil?

OLD_TESTAMENT_STRUCTURE.each do |book|
    skip = false if book[:name] == target
    next if skip
    puts "Book: #{book[:name]}"
    calculate_verify(book[:name], data_in_path, out_path)
    #break
end
