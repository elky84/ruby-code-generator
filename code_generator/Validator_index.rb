require 'simple_xlsx_reader'
require 'json'
require "fileutils"

load 'Validator_util.rb'

file_name = ARGV[0]
sheet_name = ARGV[1]
key = ARGV[2]

check_file_name = ARGV[3]
check_sheet_name = ARGV[4]
check_key = ARGV[5]

selected_sheet = get_select_sheet(file_name , sheet_name)
  
column_index = get_index_col(selected_sheet , key)

if(column_index == nil)
  abort("column_index is nil!! sheet : " + selected_sheet + ",key : " + key)
end

check_selected_sheet = get_select_sheet(check_file_name , check_sheet_name)

check_column_index = get_index_col(check_selected_sheet , check_key)

if(check_column_index == nil)
  abort("column_index is nil!! sheet : " + check_selected_sheet + ",key : " + check_key)
end

for row in 3..selected_sheet.rows.length - 1
  if selected_sheet.rows[row][column_index] == nil
    next
  else
    split = selected_sheet.rows[row][column_index].split('|');
    for cur_index in 0..split.length - 1
      is_find = false      
      find_index = split[cur_index]
      
      if(find_index == "0")
        break
      end
      
      if(!find_index.kind_of? Fixnum)
        if(find_index.split('_').length != 0)
          find_index = find_index.split('_')[0]
        end
      end
      
      for row_index in 3..check_selected_sheet.rows.length - 1
        if(check_selected_sheet.rows[row_index][check_column_index] == find_index)
          is_find = true;
          break
        end
      end
      
      if(is_find == false)
        abort(file_name + " : index check failed " + file_name + ",index : " + find_index + ", row :" + (row+1).to_s + ", col : " + (column_index).to_s26)
      end
    end
  end
end

puts(file_name + "`s index " + key + " check_complete!!");

