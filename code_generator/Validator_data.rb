require 'simple_xlsx_reader'
require 'json'
require "fileutils"

load 'Validator_util.rb'

enum_path = ARGV[0]


hash = Hash.new

def check_int(sheet,col,row_length)
  for row in 3..row_length
    if(sheet.rows[row][col].class != Numeric)
      abort(file_name + " : type check failed!! row :" + (row+1).to_s + ", col : " + (col).to_s26);
    end 
  end
end

def check_enum(sheet,col,row_length,data_type,hash)
  row_length = validate_row_length(sheet,row_length)
  for row in 3..row_length-1
    if sheet.rows[row] == nil
      next
    end
    
    if hash[data_type] == nil
      next
    end

    
    if(!hash[data_type].include?(sheet.rows[row][col]))
      abort(data_type + " : type check failed!! row :" + (row+1).to_s + ", col : " + (col).to_s26 + ", content :" + sheet.rows[row][col]);
    end 
  end
end

Dir.foreach(enum_path) do | file_name |
  if file_name.include?(".xlsx") & !file_name.include?("~$")
    puts(file_name)
    doc = SimpleXlsxReader.open(enum_path+"/"+file_name)
    add_enum_to_hash(hash , doc)
  end
end

for arg_index in 1..ARGV.length - 1
  check_path = ARGV[arg_index]
  puts("enum check path :" + check_path)
  Dir.foreach(check_path) do | file_name |
    if file_name.include?(".xlsx") & !file_name.include?("~$") & !file_name.include?("#")
    
      doc = SimpleXlsxReader.open(check_path+"/"+file_name)
      sheet = doc.sheets[0]
      
      column_length = sheet.rows[0].length
      column_length = validate_col_length(sheet , column_length)
      for col in 0..column_length
        data_type = sheet.rows[1][col]
         if data_type == nil || data_type == ""
           next
         end
         
         if data_type.include?("int")
           #check_int(sheet,col,sheet.rows.length)
         elsif data_type.include?("float")
           #check_int(sheet,col,sheet.rows.length)
         elsif data_type.include?("Vector3")
           #check_int(sheet,col,sheet.rows.length)
         elsif data_type.include?("string")
           #check_int(sheet,col,sheet.rows.length)
         elsif data_type.include?("bool")
           #check_int(sheet,col,sheet.rows.length)
         elsif data_type.include?("DateTime")
           #check_int(sheet,col,sheet.rows.length)
         elsif data_type.include?("Color")
           #check_int(sheet,col,sheet.rows.length)
         elsif data_type.include?("Int64")
           #check_int(sheet,col,sheet.rows.length)
         else
           puts("enum check :" + sheet.name + ",enum name :" + data_type)
           check_enum(sheet,col,sheet.rows.length.to_i,data_type,hash)
         end
         
      end
    end
  end
end


puts("type check_complete!!");



