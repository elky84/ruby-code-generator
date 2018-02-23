require 'simple_xlsx_reader'
require 'json'
require "fileutils"

load 'Validator_util.rb'

file_name = ARGV[0]
sheet_name = ARGV[1]
key = ARGV[2]

pre_path = ARGV[3]
index_file_name = ARGV[4]

selected_sheet = get_select_sheet(file_name , sheet_name)
  
column_index = get_index_col(selected_sheet , key)

if(column_index == nil)
  abort("column_index is nil!! sheet : " + selected_sheet + ",key : " + key)
end

doc = SimpleXlsxReader.open("%s%s" % [pre_path , index_file_name])
index_sheet = doc.sheets[0];

if index_sheet == nil
  abort("not find index_sheet: " + index_file_name)
end


for row in 3..selected_sheet.rows.length - 1
  if selected_sheet.rows[row][column_index] == nil
    next
  end
  
  split = selected_sheet.rows[row][column_index].split('|');
  if(split == nil || split == "0")
    next
  end
  
  for cur_index in 0..split.length - 1
    is_find = false      
    find_index = split[cur_index]
    
    if(find_index.split('_').length != 2)
      abort("find index form not match :" + find_index + ", row :" + (row+1).to_s + ", col : " + (column_index).to_s26)
    end
    
    file_index = find_index.split('_')[0]
    reaction_index = find_index.split('_')[1]
    
    check_file_name = "%02d" % index_sheet.rows[file_index.to_i+2][0].to_s
    check_file_name += '_' +index_sheet.rows[file_index.to_i+2][2].to_s + '.xlsx'

    check_selected_sheet = get_select_sheet(pre_path+check_file_name , index_sheet.rows[file_index.to_i+2][2])
    
    for row_index in 3..check_selected_sheet.rows.length - 1
      if(check_selected_sheet.rows[row_index][0].to_i == reaction_index.to_i)
        is_find = true;
        break
      end
    end
    
    if(is_find == false)
      abort("index check failed index : " + find_index + ", row :" + (row+1).to_s + ", col : " + (column_index).to_s26)
    end
    
  end
  puts("index row check row :" + row.to_s + ",check_index :" + selected_sheet.rows[row][column_index].to_s)
  
end

puts(file_name + "`s index " + key + " check_complete!!");

