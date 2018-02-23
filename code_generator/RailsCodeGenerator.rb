require "fileutils"

class RailsCodeGenerator
  def self.to_scaffold_command(destination, class_name, rows, column_length, key)
    
    code = "cd ..\\web_server\n"
    code += "call rails generate scaffold #{class_name} "
    
    parameters = String.new
    for value in 0...column_length
      name = rows[0][value]
      type = rows[1][value]
      
      if type.include?("List")
        type = "text"
      elsif (type.include?("int")) || (type.include?("bool")) || (type.include?("Int64")) 
        type = "integer"
      elsif type.include? "double"
        type = "decimal"
      elsif type.include? "DateTime"
        type = "timestamp"
      elsif name.include? "Type" # 이름으로 Type이 포함된 값은 index로 지정될 가능성 및 enum 일 가능성이 높으므로 string 처리
	    type = "string"
	  else 
      	type = "text"
      end 
       
  	  if name == key
        parameters += " #{name}:#{type}:index"
      else
        parameters += " #{name}:#{type}"
  	  end  	 
    end 
      
    code = code + parameters + " --force" + "\n"    # 새로 만들거나 덮어 쓸때 기존의 데이터를 새로운 데이터로 바꾼다
	      
    code = code + "cd ..\\scaffold\n"
    code = code + "call ruby modify_create_method.rb #{class_name} #{key}\n"
    code = code + "call ruby modify_before_action.rb #{class_name} #{key}\n"
    code = code + "call ruby modify_index_method.rb #{class_name} #{key}\n"
    code = code + "call ruby modify_model.rb #{class_name} #{key}\n"
    
    dir = "#{destination}\\..\\web\\scaffold"
    if Dir.exists?(dir) == false
      FileUtils::mkdir_p(dir)
    end
    
    #puts dir
    
    file = File.open("#{dir}\\#{class_name}.bat", 'w') 
    file.write(code)
  end
end