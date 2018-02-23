require 'simple_xlsx_reader'
require 'json'
require "fileutils"

load 'Validator_util.rb'


file_name = ARGV[0]
sheet_name = ARGV[1]

selected_sheet = get_select_sheet(file_name , sheet_name)

for row in 3..selected_sheet.rows.length - 1
  splite_count = 0
  for arg in 2..ARGV.length - 1
    column_index = get_index_col(selected_sheet , ARGV[arg])
    if selected_sheet.rows[row][column_index] == nil
      break
    elsif splite_count == 0
      splite_count = selected_sheet.rows[row][column_index].split('|').length
    elsif splite_count != selected_sheet.rows[row][column_index].split('|').length
      abort(sheet_name + " : pail not match at " + ARGV[arg] + " table count :" + splite_count.to_s + " , row : " + (row+1).to_s + ", col : " + column_index.to_s26 + ", count : " + selected_sheet.rows[row][column_index].split('|').length.to_s)  
    end
  end
end

result = "pail check_complete!! key :"

for arg in 2..ARGV.length - 1
  result << ARGV[arg]
  result << ','
end  
puts(result)
