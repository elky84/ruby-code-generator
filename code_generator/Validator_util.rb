require 'simple_xlsx_reader'
require 'json'
require "fileutils"
require 'find'


class Numeric
  Alpha26 = ("A".."Z").to_a
  def to_s26
    return "" if self < 1
    s, q = "", self
    loop do
      q, r = (q).divmod(26)
      s.prepend(Alpha26[r]) 
      break if q.zero?
    end
    s
  end
end

#key_name의 컬럼 인덱스를 리턴
def get_index_col(sheet_find , key_name)
  column_length = sheet_find.rows[0].length
  
  for col in 0..column_length -1
    if sheet_find.rows[0][col] == nil
      puts "can`t find index key!! index key :" + key_name
      break
    elsif(sheet_find.rows[0][col] == key_name)
      return col
    end
  end
end

#file_name을 가지고 sheet find
def get_select_sheet(file_name,sheet_name)
  doc = SimpleXlsxReader.open(file_name)
  
  sheet_select = nil
  
  doc.sheets.each do |sheet|
    if sheet_name != sheet.name
       #puts sheet.name
      next
    end
  
    sheet_select = sheet
    break
  end
  
  if sheet_select == nil
    abort("not find sheet: " + sheet_name)
  end
  
  return sheet_select
end

def file_exist(pre_path,file_name)
  Find.find(pre_path) do |path|
    if FileTest.directory?(path)
      if File.basename(path)[0] == ?.
        Find.prune       # Don't look any further into this directory.
      else
        next
      end
    else
      if path.include?(file_name)
        return true
      end
    end
  end
  
  return false
end

def validate_row_length(selected_sheet , row_length)
  # 유효한 row를 검사해내기 위한 재 검사 코드
  for row in 0..row_length - 1
    if selected_sheet.rows[row][0] == nil
      #puts "find nil data. resize row length: " + row.to_s + " sheet_name: " + selected_sheet.name + " row: " + row.to_s + " col: 0"
      row_length = row
      break
    end
  end
  
  return row_length
end

def validate_col_length(selected_sheet , column_length)
  # 유효한 컬럼 크기를 알아내기 위한 재 검사 코드
    for col in 0..column_length -1
      if selected_sheet.rows[0][col] == nil
        #puts "find nil data. resize column length: " + col.to_s + " sheet_name: " + selected_sheet.name + " row: 0 col: " + col.to_s
        column_length = col
        break
      end
    end
  
  return column_length
end

#해쉬에 enum을 추가
def add_enum_to_hash(hash,doc)
  for selected_sheet in doc.sheets
    row_length = selected_sheet.rows.length
    column_length = selected_sheet.rows[0].length
    
    row_length = validate_row_length(selected_sheet,row_length)
    column_length = validate_col_length(selected_sheet,column_length)
    
    for row in 3...row_length
    
      arr_row = selected_sheet.rows[row]
    
      # 변환 완료 후 담자  
      if(hash[selected_sheet.name] == nil)
        array = Array.new
      else
        array = hash[selected_sheet.name]
      end
      
      array.push(arr_row[0])
      hash[selected_sheet.name] = array
    end
  end
end
