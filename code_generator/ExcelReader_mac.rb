require 'simple_xlsx_reader'
require 'json'
require "fileutils"
require 'time'
require 'digest/md5'

load 'UnityCodeGenerator.rb'
load 'RailsCodeGenerator.rb'
load 'RailsPost.rb'

file_name = "Character.xlsx"
sheet_name = "CharacterData"
key = "Index"
option = "rails_scaffold|unity|multimap|json|http_get:sign_in|http_update"
#option = "rails_post:http://127.0.0.1:3000"

destination = "./test/"
web_address = nil

puts ARGV[0]

def assign_argv(val, argv)
  if argv != nil
    return argv
  else
	return val
  end
end

file_name = assign_argv(file_name, ARGV[0])
sheet_name = assign_argv(sheet_name, ARGV[1])
key = assign_argv(key, ARGV[2])
option = assign_argv(option, ARGV[3])
destination = assign_argv(destination, ARGV[4])
build_target = assign_argv(build_target, ARGV[5])
target_dic = assign_argv(target_dic, ARGV[6])

puts "#{target_dic}"

doc = SimpleXlsxReader.open(file_name)

option = option.downcase

#puts doc.sheets  


selected_sheet = nil

doc.sheets.each do |sheet|
  if sheet_name != sheet.name
	   #puts sheet.name
    next
  end

  selected_sheet = sheet
  break
end
  

if selected_sheet == nil
	abort("not find sheet: " + sheet_name)
end

puts "trying convert " + sheet_name + " sheet."
 
sheet_name_lower = selected_sheet.name.downcase

row_length = selected_sheet.rows.length
column_length = selected_sheet.rows[0].length

# 유효한 컬럼 크기를 알아내기 위한 재 검사 코드
for col in 0..column_length -1
	if selected_sheet.rows[0][col] == nil
		puts "find nil data. resize column length: " + col.to_s + " sheet_name: " + selected_sheet.name + " row: 0 col: " + col.to_s
		column_length = col
		break
	end
end

# 유효한 row를 검사해내기 위한 재 검사 코드
for row in 0..row_length - 1
	if selected_sheet.rows[row][0] == nil
		puts "find nil data. resize row length: " + row.to_s + " sheet_name: " + selected_sheet.name + " row: " + row.to_s + " col: 0"
		row_length = row
		break
	end
end

puts "row_length: " + row_length.to_s + " column_length: " + column_length.to_s  


h = Hash.new  
#offset = ActiveSupport::TimeZone.new('Asia/Seoul').utc_offset()

for row in 0...row_length
	for col in 0..column_length -1
		#puts selected_sheet.rows[row][col]
		if 2 < row && selected_sheet.rows[1][col].to_s != "string"
			if selected_sheet.rows[row][col] == nil
				abort("find nil data. failed generate data. sheet_name:  " + selected_sheet.name + " row: " + row.to_s + " col: " + col.to_s)		
			end
		end
		
		content = selected_sheet.rows[row][col].to_s
		if content[content.size-1] == "|"
			abort("find invalid data. don't use last character is |. content: " + content + "sheet_name:  " + selected_sheet.name + " row: " + row.to_s + " col: " + col.to_s)
		end


		if 2 < row && selected_sheet.rows[1][col].to_s == "DateTime"
		  time = Time.parse(content)
      #time = time.in_time_zone("Asia/Seoul")
      #time += -offset

      selected_sheet.rows[row][col] = time.iso8601
		end			
	end
	
	 #user_name = ENV['username']
   	 
	 if option.include? "json_onlyfile"      
    if row > 2

	  puts "#{target_dic}"
      dir = "#{target_dic}/#{selected_sheet.rows[row][3]}"
      puts "dir = #{dir}/#{selected_sheet.rows[row][1]}.#{selected_sheet.rows[row][4]}"
      md5 = Digest::MD5.file("#{dir}/#{selected_sheet.rows[row][1]}.#{selected_sheet.rows[row][4]}").hexdigest
      puts "#{md5}"
      selected_sheet.rows[row][2] = md5
    end
  end

  # 변환 완료 후 담자	
  arr_row = selected_sheet.rows[row]
	h[selected_sheet.rows[row][0]] = arr_row[0, column_length]
end

arr = option.split("|")
arr.each do |str|
	if str.include? "rails_post"
	  web_address = str[str.index(":") + 1, str.length]
	end

	splited = str.split(":")
	command = splited[0]
	param = splited[1]
	
	if command.include? "unity"
		UnityCodeGenerator.to_class(destination, selected_sheet.name, selected_sheet.rows, column_length)
	end

	if command.include? "rails_scaffold"
		RailsCodeGenerator.to_scaffold_command(destination, sheet_name_lower, selected_sheet.rows, column_length, key) # scaffold 명령 생성
	end

	if command.include? "rails_post"
		RailsPost.run(key, sheet_name_lower, web_address, selected_sheet.rows, row_length, column_length)
	end

	if command.include? "http_get"
		UnityCodeGenerator.json_to_http_get_class(destination, selected_sheet.name, selected_sheet.rows, column_length, key, option)
	end

	if command.include? "http_update"
		UnityCodeGenerator.json_to_http_update_class(destination, selected_sheet.name, selected_sheet.rows, column_length, key, option)
	end

	if command.include? "enum"
		UnityCodeGenerator.to_enum(destination, selected_sheet.name, selected_sheet.rows, row_length)
	end

	if command.include? "json"
	  loader_create = true
	  make_json_file = true
	  
	  if command.include? "json_onlyfile"
	    loader_create = false
	  elsif param == "parser"
	    make_json_file = false
	  end
	  
	  if loader_create == true
  	  UnityCodeGenerator.json_to_loader_class(destination, selected_sheet.name, selected_sheet.rows, column_length, key, option) # json loader 클래스 생성
	  end
	  
	  if make_json_file == true
  	  for value in 0..2 # 0은 컬럼이름, 1은 변수 타입, 2는 한글 컬럼명이므로 제거한다.
  		  h.delete(selected_sheet.rows[value][0]) 
  	  end
  	  
  	  #user_name = ENV['username']
  	  
  	  dir = "#{target_dic}/JSON"
  	  if option.include? "json_onlyfile"
  	    dir = "#{target_dic}/List"
  	  end  	  
  	  if Dir.exists?(dir) == false
  		  FileUtils::mkdir_p(dir)
  	  end
  	  
  	  puts "#{dir}/#{selected_sheet.name}.json make!!"
  	  if build_target == "Android"
  	    file = File.open("#{dir}/#{selected_sheet.name}_#{build_target}.json", 'w')
  	  elsif build_target == "PC"
  	    file = File.open("#{dir}/#{selected_sheet.name}_#{build_target}.json", 'w')
  	  else
  	    file = File.open("#{dir}/#{selected_sheet.name}.json", 'w')
  	  end
  	  
  	   
  	  file.write(h.to_json)
  	end
	end	
	
end
  
puts "Process Completed\n\n"
