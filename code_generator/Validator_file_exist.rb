require 'simple_xlsx_reader'
require 'json'
require "fileutils"
require 'find'

load 'Validator_util.rb'

file_name = ARGV[0]
sheet_name = ARGV[1]
key = ARGV[2]

file_path = ARGV[3]
extension = ARGV[4]

selected_sheet = get_select_sheet(file_name , sheet_name)

column_index = get_index_col(selected_sheet , key)

for row in 3..selected_sheet.rows.length - 1
  if selected_sheet.rows[row][column_index] == nil
    break
  else
    split = selected_sheet.rows[row][column_index].split('|');
    for cur_index in 0..split.length - 1
      find_file_name = split[cur_index]
      if find_file_name == "0"
        next
      end
      
      path_split = file_path.split('|')
      is_find = false
      for path_index in 0..path_split.length - 1
        if(File.exist?(path_split[path_index]+'/'+find_file_name+'.'+extension) )
          is_find = true          
          break
        end
      end
      if(!is_find)
        abort(file_name + " : can`t find file : " + file_path + '/' + find_file_name + '.' + extension)
      end
    end
  end
end

puts(file_name + "`s file name : " + key + " : is check_complete!!");
