
def run_cmd(&block)
    res = yield block

    if $?.exitstatus != 0
        puts "failure"
        puts res
        exit 1
    end
end

def duration_to_ms(duration)
    hours, minutes, seconds = duration.split(':').map(&:to_f)
    (hours * 3600 + minutes * 60 + seconds) * 1000
end

def ms_to_duration(timestamp, digits = 3)
    seconds_timestamp = timestamp.to_f / 1000.0
    hours = (seconds_timestamp / 3600).to_i
    minutes = ((seconds_timestamp - (hours * 3600)) / 60).to_i
    seconds = (seconds_timestamp - (hours * 3600) - (minutes * 60)).round(2)


    seconds_list = seconds.to_s.split(/\./)

    seconds_list[1] += "0" * (digits - seconds_list[1].size) if seconds_list[1].size < digits
    seconds_list[1] = seconds_list[1][0..2] if seconds_list[1].size > digits

    second_str = "#{'%02d' % seconds_list[0].to_i}.#{seconds_list[1]}"

    return "#{'%02d' % hours}:#{'%02d' % minutes}:#{second_str}"
end

def titleize(title)
    title.split(/ |\_/).map(&:capitalize).join(" ")
end

def generate_uid
  rand(10**18..10**19 - 1)
end