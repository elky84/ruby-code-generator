require 'simple_xlsx_reader'
require 'json'
require "fileutils"

load 'Validator_util.rb'

file_name = ARGV[0]
sheet_name = ARGV[1]
key = ARGV[2]

selected_sheet = get_select_sheet(file_name , sheet_name)
  
column_index = get_index_col(selected_sheet , key)

if(column_index == nil)
  abort("column_index is nil!! sheet : " + selected_sheet + ",key : " + key)
end

for row in 3..selected_sheet.rows.length - 1
  if selected_sheet.rows[row][column_index] == nil
    next
  else
    split = selected_sheet.rows[row][column_index].split('|');
    for cur_index in 0..split.length - 1
      cur_string = split[cur_index]
      if(cur_string == nil || cur_string == "0")
        next
      end
      
      if(cur_string.split('[').length != 7)
        abort(file_name + " : damage [ is not 7 row :" + row.to_s + ",length =" + cur_string.split('[').length.to_s)
      end
      
      if(cur_string.split(']').length != 6)
        abort(file_name + " : damage ] is not 6 row :" + row.to_s + ",length =" + cur_string.split(']').length.to_s)
      end 
    end
  end
end

puts(file_name + "`s index " + key + " check_complete!!");