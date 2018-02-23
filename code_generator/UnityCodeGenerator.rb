require "fileutils"

def write(tab_count, code, string)
  if string.include? "}"
    tab_count -= 1
	string += "\n"
  end
   
  for value in 0...tab_count
    code << "\t"
  end
  
  if string.include? "{"
    tab_count += 1
  end
   
  code << string
  code << "\n"
  
  return tab_count
end

class UnityCodeGenerator
  def self.is_base_type(type)
    if type == "int" || type == "float" || type == "DateTime" || type == "Int64"
      return true
    else
      return false
    end
  end
  
  def self.parse_http_option(option, key)
  	action, tag = nil
  	param = "single" # default option
  	result = "multi" # default option
  	arr = option.split("|")
    arr.each do |str|
      if str.include? key
  	    splitted = str.split(":")
        action = splitted[1]		
  	
    		for n in 2..splitted.length-1
          temp = splitted[n].split("_")
      		if temp[0] == "param"
            param = temp[1]
          elsif temp[0] == "result"
            result = temp[1]          
      		end
    		end
  	    		    
    		if action != nil
    			tag = action.gsub("/", "_").upcase
    			tag = tag.gsub(".JSON", "")
    			return action, tag, param, result
    		end		
      end
    end
  	return action, tag, param, result
  end
  
  def self.parse_json_option(option)
    file_read = true
    result = "multi"
    arr = option.split("|")
    arr.each do |str|
      if str.include? "json"
        splitted = str.split(":")
        if splitted[1] == nil
          break
        end
        
        for n in 1..splitted.length-1
          if splitted[n] == "parser"
            file_read = false
          end

          temp = splitted[n].split("_")
          if temp == nil
            next
          end
          
          if temp[0] == "result"
            result = temp[1]
          end
          
        end        
      end
    end
    return file_read, result
  end
  
  def self.using_code()
  	code = String.new
  	code += "using UnityEngine;\n"
    code += "using System.Collections.Generic;\n"
    code += "using System.Text;\n"
    code += "using System.IO;\n"
    code += "using System.Collections;\n"
    code += "using System;\n\n"
    return code
  end
  
  def self.error_check(tab_count, code, error_code, condition, popup)
    tab_count = write(tab_count, code, "if( #{condition} )")
    tab_count = write(tab_count, code, "{")
    tab_count = write(tab_count, code, "string code = #{error_code};")
    tab_count = write(tab_count, code, popup)
    tab_count = write(tab_count, code, "if(callback != null)")
    tab_count = write(tab_count, code, "{")  
    tab_count = write(tab_count, code, "callback(null);")
    tab_count = write(tab_count, code, "}")
    tab_count = write(tab_count, code, "PopupUtil.remove_web_lock_count();")
    tab_count = write(tab_count, code, "return;")
    tab_count = write(tab_count, code, "}")
    return tab_count     
  end
  
  def self.popup_yesno()
    return 'PopupUtil.popup_yesno("NOTICE", "<UI_TEXT>" + code + "<UI_TEXT_END>" + "\\n" + "<" + int.Parse(code) + ">", retry);'
  end
  
  def self.popup_ok()
    return 'PopupUtil.popup_ok("NOTICE", "<UI_TEXT>" + code + "<UI_TEXT_END>" + "\\n" + "<" + int.Parse(code) + ">");'
  end
  
  def self.error_handling_code(tab_count, code)
    tab_count = error_check(tab_count, code, '"120000"', 'request.response == null', popup_yesno())
    tab_count = write(tab_count, code, 'json_obj = new JSONObject(request.response.Text);')
    tab_count = error_check(tab_count, code, '"120001"', 'json_obj.IsNull || json_obj.GetField("error")', popup_yesno())
    tab_count = error_check(tab_count, code, 'Util.json_to_string(json_obj, "code")', 'json_obj.GetField("retry")', popup_yesno())
    tab_count = error_check(tab_count, code, 'Util.json_to_string(json_obj, "code")', 'json_obj.GetField("message") || json_obj.GetField("contents_error")', popup_ok())	
	  return tab_count
  end
  
  def self.try_catch(tab_count, code, rows, column_length, file_read)
      tab_count = write(tab_count, code, "try{")  
      tab_count = type_to_data(tab_count, code, rows, column_length, file_read)
      tab_count = write(tab_count, code, "}")
      tab_count = write(tab_count, code, "catch(Exception e){")
      tab_count = write(tab_count, code, "DebugLog.assert(e.ToString());")
      tab_count = write(tab_count, code, "}")
  end
  
  def self.data_mapping_code(tab_count, code, container_type, key, key_type, class_name, column_length, rows, result, file_read)
    if result == "multi"
      tab_count = write(tab_count, code, "#{class_name} instance = null;")
  		tab_count = write(tab_count, code, "foreach(var value in json_obj.list)")
  		tab_count = write(tab_count, code, "{")
      if file_read == true
        tab_count = write(tab_count, code, "var row = value;")
      else
        tab_count = write(tab_count, code, "var row = value.ToDictionary();")
      end
      tab_count = write(tab_count, code, "instance = new #{class_name}();")
      tab_count = try_catch(tab_count, code, rows, column_length, file_read)  
  	elsif result == "custom"
  	  return tab_count
  	else
      if file_read == true
        tab_count = write(tab_count, code, "var row = json_obj;")
      else
        tab_count = write(tab_count, code, "var row = json_obj.ToDictionary();")
      end
      tab_count = write(tab_count, code, "instance = new #{class_name}();")
      tab_count = try_catch(tab_count, code, rows, column_length, file_read)  
  	end

   	return tab_count
  end
  
  def self.wrap_quot(str)
    return '"' + str + '"'
  end
  
  def self.type_to_data(tab_count, code, rows, column_length, file_read)
    for value in 0...column_length
        name = rows[0][value]
        type = rows[1][value]
                  
        if file_read
          row_acess = "Util.json_to_string(row, #{value.to_s})"
        else
          row_acess = "row[\"#{name}\"]"
        end 
         
        if type == "Int64" || type == "int"
          tab_count = write(tab_count, code, "instance.#{name} = #{type}.Parse(Double.Parse(#{row_acess}).ToString());")
        elsif type == "string"
          tab_count = write(tab_count, code, "instance.#{name} = #{row_acess};")
        elsif type == "Color" 
          tab_count = write(tab_count, code, "{")
          tab_count = write(tab_count, code, "string str = #{row_acess};")
          tab_count = to_color(tab_count, code, type, name)       
          tab_count = write(tab_count, code, "}")
        elsif type == "bool" # C#과 rails에서의 bool룰 보정을 위해 
          tab_count = write(tab_count, code, "instance.#{name} = Util.ConvertToBoolean(#{row_acess});")
        elsif is_base_type(type)
          tab_count = write(tab_count, code, "instance.#{name} = #{type}.Parse(#{row_acess});")
        elsif type.include? "List"
          tab_count = write(tab_count, code, "{")
          tab_count = write(tab_count, code, "string str = #{row_acess};")
          tab_count = to_list(tab_count, code, type, name)       
          tab_count = write(tab_count, code, "}")
        elsif type == "Vector3"
          tab_count = write(tab_count, code, "{")
          tab_count = write(tab_count, code, "string str = #{row_acess};")
          tab_count = to_vector3(tab_count, code, type, name)
          tab_count = write(tab_count, code, "}")
        else # enum 형이라 가정한다
          tab_count = write(tab_count, code, "instance.#{name} = (#{type})System.Enum.Parse(typeof(#{type}), #{row_acess});")
        end
        
      end
      
      return tab_count
  end
  
  def self.to_color(tab_count, code, type, name)
    tab_count = write(tab_count, code, "string[] arr = str.Split(',');")
    tab_count = write(tab_count, code, "instance.#{name} = new #{type}(float.Parse(arr[0]), float.Parse(arr[1]), float.Parse(arr[2]), float.Parse(arr[3]));")
    return tab_count
  end
  
  def self.to_list(tab_count, code, type, name)
    tab_count = write(tab_count, code, "string[] arr = str.Split('|');")
    tab_count = write(tab_count, code, "instance.#{name} = new #{type}();")
    element_type = type[type.index("<")+1..type.index(">")-1]
    
    tab_count = write(tab_count, code, "for(int n = 0; n < arr.Length; ++n)")
    tab_count = write(tab_count, code, "{")
	  if element_type == "string"
	    tab_count = write(tab_count, code, "instance.#{name}.Add(arr[n]);")
    elsif is_base_type(element_type)
      tab_count = write(tab_count, code, "instance.#{name}.Add(#{element_type}.Parse(arr[n]));")
    else
      tab_count = write(tab_count, code, "instance.#{name}.Add((#{element_type})System.Enum.Parse(typeof(#{element_type}), arr[n]));")
    end 
    
    tab_count = write(tab_count, code, "}")
    return tab_count
  end
  
  def self.to_vector3(tab_count, code, type, name)
      tab_count = write(tab_count, code, "string[] arr = str.Substring(1, str.Length - 2).Split(',');")
      tab_count = write(tab_count, code, "instance.#{name} = new Vector3( float.Parse(arr[0]), float.Parse(arr[1]), float.Parse(arr[2]));")
      return tab_count
  end
  
  def self.to_class(destination, class_name, rows, column_length)

	  header = using_code()
    
    class_begin = "public class #{class_name} {\n"
    
    parameters = String.new
    for value in 0...column_length
      name = rows[0][value]
      type = rows[1][value]
      comment = rows[2][value]      
      
      parameters += "\t" + "public #{type} #{name}; // #{comment}\n"
    end 
    parameters += "\n"
    
    tab_count = 0
    
    function = String.new
    tab_count = write(tab_count, function, "public #{class_name} Clone() {")
    tab_count = write(tab_count, function, "#{class_name} instance = new #{class_name}();")
    tab_count = write(tab_count, function, "instance = this;")
    tab_count = write(tab_count, function, "return instance;")    
    tab_count = write(tab_count, function, "}")
    
    class_end = "}"
    
    code = header + class_begin + parameters + function + class_end
    
    dir = "#{destination}\\Assets\\Scripts\\Excel"
    if Dir.exists?(dir) == false
      FileUtils::mkdir_p(dir)
    end

    file = File.open("#{dir}\\#{class_name}.cs", 'w') 
    file.write(code)
  end
    
	
  def self.json_to_http_get_class(destination, class_name, rows, column_length, key, option)
    if option.include? "multimap"
      container_type = "MultiSortedDictionary"
    else
      container_type = "Dictionary"
    end      
  
    action, tag, param, result = parse_http_option(option, "http_get")
  
    tab_count = 0
    retry_name = "";

    header = using_code()
      
    key_type = String.new
    
    for value in 0...column_length
      name = rows[0][value]
      type = rows[1][value]
      
      if name == key
        key_type = type
      end
    end
    	
    code = String.new
    if action == nil  
		  tab_count = write(tab_count, code, "public class #{class_name}_Http_get : ScriptableObject {")
		  retry_name = class_name + "_Http_get";
    else
		  tab_count = write(tab_count, code, "public class #{tag}_Http_get : ScriptableObject {")
		  retry_name = tag + "_Http_get";
	  end

    return_type = String.new
    if result == "multi"
      return_type = "void"
      tab_count = write(tab_count, code, "public delegate void delegate_#{class_name}(#{container_type}<#{key_type}, #{class_name}> callback);")
    elsif result == "custom"
      return_type = "void"
      tab_count = write(tab_count, code, "public delegate void delegate_#{class_name}(JSONObject callback);")
    else
      return_type = "void"
      tab_count = write(tab_count, code, "public delegate void delegate_#{class_name}(#{class_name} callback);")
    end
    
    param_code = String.new
  	if param == "multi"
  		param_code = "#{container_type}<#{key_type}, #{class_name}> dict, string web_address = null"
  		tab_count = write(tab_count, code, "static #{container_type}<#{key_type}, #{class_name}> dict_;")
    elsif param == "custom"
      param_code = "Hashtable hash, string args = \"\", string web_address = null"
      tab_count = write(tab_count, code, "static Hashtable hash_;")
      tab_count = write(tab_count, code, "static string args_;")
  	else
      param_code = "string args , delegate_#{class_name} callback , bool sync = false, string web_address = null"
      tab_count = write(tab_count, code, "static string args_;")
      tab_count = write(tab_count, code, "static delegate_#{class_name} callback_;")
      tab_count = write(tab_count, code, "static bool sync_;")
  	end

    tab_count = write(tab_count, code, "public static #{return_type} Call(#{param_code}) {")
    
    # this code reason to look at below
    # http://stackoverflow.com/questions/2729639/setting-the-default-value-of-a-c-sharp-optional-parameter
    tab_count = write(tab_count, code, "web_address = web_address == null ? Configuration.Instance.WEB_ADDRESS_CONTENTS : web_address;")
    tab_count = write(tab_count, code, "PopupUtil.add_web_lock_count();")
    
    tab_count = write(tab_count, code, "JSONObject json_obj = null;")    
    if result == "multi"
      tab_count = write(tab_count, code, "#{container_type}<#{key_type}, #{class_name}> dic = new #{container_type}<#{key_type}, #{class_name}>();") 
    elsif result == "custom"
    else
      tab_count = write(tab_count, code, "#{class_name} instance = null;")
    end


    if action == nil  
      tab_count = write(tab_count, code, "HTTP.Request theRequest = new HTTP.Request(\"get\", web_address + \"#{class_name.downcase.pluralize}.json\" + args);")
    else
      tab_count = write(tab_count, code, "HTTP.Request theRequest = new HTTP.Request(\"get\", web_address + \"#{action}\" + args);")
    end
    
    tab_count = write(tab_count, code, "theRequest.synchronous = sync;")
    
    if param == "multi"
      tab_count = write(tab_count, code, "dict_ = dict;")
    elsif param == "custom"
      tab_count = write(tab_count, code, "hash_ = hash;")
      tab_count = write(tab_count, code, "args_ = args;")
    else
      tab_count = write(tab_count, code, "args_ = args;")
      tab_count = write(tab_count, code, "callback_ = callback;")
      tab_count = write(tab_count, code, "sync_ = sync;")
    end
        
    tab_count = write(tab_count, code, "theRequest.Send((request) =>")
    tab_count = write(tab_count, code, "{")    
    
    tab_count = error_handling_code(tab_count, code)
    
    tab_count = data_mapping_code(tab_count, code, container_type, key, key_type, class_name, column_length, rows, result, false)
    
    if result == "multi"
      tab_count = write(tab_count, code, "dic.Add(instance.#{key}, instance);")
      tab_count = write(tab_count, code, "}")  
    end

    tab_count = write(tab_count, code, "if(callback != null)")
    tab_count = write(tab_count, code, "{")  
    tab_count = write(tab_count, code, "callback(#{callback_type(result)});")
    tab_count = write(tab_count, code, "}")
    tab_count = write(tab_count, code, "PopupUtil.remove_web_lock_count();")
    tab_count = write(tab_count, code, "});")

    tab_count = write(tab_count, code, "}")
    
    #retry 코드 작성
    tab_count = write(tab_count, code, "public static bool retry()")
    tab_count = write(tab_count, code, "{")
    
    if param == "multi"
      tab_count = write(tab_count, code, "Call(dict_);")
    elsif param == "custom"
      tab_count = write(tab_count, code, "Call(hash_,args_);")
    else
      tab_count = write(tab_count, code, "Call(args_,callback_,sync_);")
    end
    tab_count = write(tab_count, code, "return true;")
    
    tab_count = write(tab_count, code, "}")
    
    tab_count = write(tab_count, code, "}")
    
    code = header + code
    
    dir = "#{destination}\\Assets\\Scripts\\Http\\"
    if Dir.exists?(dir) == false
      FileUtils::mkdir_p(dir)
    end
    
	if action == nil  
		file = File.open("#{dir}\\#{class_name}_Http_get.cs", 'w')
	else
		file = File.open("#{dir}\\#{tag}_Http_get.cs", 'w') 
	end

    file.write(code)
  end
    
  def self.composite_args(tab_count, code)
    tab_count = write(tab_count, code, "if (args.Length == 0)")
    tab_count = write(tab_count, code, "{")
    tab_count = write(tab_count, code, "args = \"?\";")
    tab_count = write(tab_count, code, "}")
    tab_count = write(tab_count, code, "else")
    tab_count = write(tab_count, code, "{")
    tab_count = write(tab_count, code, "args = args + \"&\";")
    tab_count = write(tab_count, code, "}")

    tab_count = write(tab_count, code, "args = args + \"COUNT=\" + hash.Count;\n")
    return tab_count
  end
    
  def self.callback_type(result)
    if result == "custom"  
        return "json_obj"
    elsif result == "single"
      return "instance"
    else
      return "dic"
    end
  end
    
  def self.json_to_http_update_class(destination, class_name, rows, column_length, key, option)
    if option.include? "multimap"
      container_type = "MultiSortedDictionary"
    else
      container_type = "Dictionary"
    end      
  
	  action, tag, param, result = parse_http_option(option, "http_update")
  
    tab_count = 0
    retry_name = "";

    header = using_code()
         
    key_type = String.new
    
    for value in 0...column_length
      name = rows[0][value]
      type = rows[1][value]
      
      if name == key
        key_type = type
      end
    end
    
    code = String.new
    if action == nil  
		  tab_count = write(tab_count, code, "public class #{class_name}_Http_update : ScriptableObject {")
		  retry_name = class_name + "_Http_update";
    else
		  tab_count = write(tab_count, code, "public class #{tag}_Http_update : ScriptableObject {")
		  retry_name = tag + "_Http_update";
	  end
  
    return_type = String.new
    if result == "multi"
      return_type = "void"
      tab_count = write(tab_count, code, "public delegate void delegate_#{class_name}(#{container_type}<#{key_type}, #{class_name}> callback);")
    elsif result == "custom"
      return_type = "void"
      tab_count = write(tab_count, code, "public delegate void delegate_#{class_name}(JSONObject callback);")
    else
      return_type = "void"
      tab_count = write(tab_count, code, "public delegate void delegate_#{class_name}(#{class_name} callback);")
    end

    param_code = String.new
    if param == "multi"
      param_code = "#{container_type}<#{key_type}, #{class_name}> dict, string args = \"\" , delegate_#{class_name} callback = null, bool sync = false, string web_address = null"
      tab_count = write(tab_count, code, " static #{container_type}<#{key_type}, #{class_name}> dict_;")
    elsif param == "custom"
      param_code = "Hashtable hash, string args = \"\" , delegate_#{class_name} callback = null, bool sync = false, string web_address = null"
      tab_count = write(tab_count, code, " static Hashtable hash_;")
    elsif param == "none"
      param_code = "string args = \"\" , delegate_#{class_name} callback = null, bool sync = false, string web_address = null"
    else
      param_code = "#{class_name} inst, string args = \"\" , delegate_#{class_name} callback = null, bool sync = false, string web_address = null"
      tab_count = write(tab_count, code, " static #{class_name} inst_;")
    end

    tab_count = write(tab_count, code, " static string args_;")
    tab_count = write(tab_count, code, " static delegate_#{class_name} callback_;")
    tab_count = write(tab_count, code, " static bool sync_;")
  
    tab_count = write(tab_count, code, "public static #{return_type} Call(#{param_code}) {")

    # this code reason to look at below
    # http://stackoverflow.com/questions/2729639/setting-the-default-value-of-a-c-sharp-optional-parameter
    tab_count = write(tab_count, code, "web_address = web_address == null ? Configuration.Instance.WEB_ADDRESS_CONTENTS : web_address;")

    tab_count = write(tab_count, code, "PopupUtil.add_web_lock_count();")

    tab_count = write(tab_count, code, "JSONObject json_obj = null;") 
  	if result == "multi"
      tab_count = write(tab_count, code, "#{container_type}<#{key_type}, #{class_name}> dic = new #{container_type}<#{key_type}, #{class_name}>();") 
    elsif result == "custom"
    else
      tab_count = write(tab_count, code, "#{class_name} instance = null;")
    end

    tab_count = write(tab_count, code, "args_ = args;")
    tab_count = write(tab_count, code, "callback_ = callback;")
    tab_count = write(tab_count, code, "sync_ = sync;")

  	if param == "multi"
  	  tab_count = write(tab_count, code, "dict_ = dict;")
  	  
  		tab_count = write(tab_count, code, "int i = 0;")
  		tab_count = write(tab_count, code, "Hashtable hash = new Hashtable();")
  	 
  		tab_count = write(tab_count, code, "foreach (var pair in dict)")
  		tab_count = write(tab_count, code, "{")
  		tab_count = write(tab_count, code, "Dictionary<string, string> dic_string = ScriptsUtil.to_dictionary(pair.Value);")
  		tab_count = write(tab_count, code, "hash.Add(\"PARAMS_\" + i++, new Hashtable(dic_string));")
  		tab_count = write(tab_count, code, "}")
  		
  		tab_count = composite_args(tab_count, code)
    elsif param == "none"
  	elsif param == "custom"
  	  tab_count = write(tab_count, code, "hash_ = hash;")
      
      tab_count = composite_args(tab_count, code)
  	else
  	  tab_count = write(tab_count, code, "inst_ = inst;")
      
  		tab_count = write(tab_count, code, "Dictionary<string, string> dic_string = ScriptsUtil.to_dictionary(inst);")
  		tab_count = write(tab_count, code, "Hashtable hash = new Hashtable(dic_string);")		
  	end
  	
		
    if action == nil  
      tab_count = write(tab_count, code, "HTTP.Request theRequest = new HTTP.Request(\"post\", web_address + \"#{class_name.downcase.pluralize}.json\" + args, hash);")
    else
      if param == "none" ## 파라미터가 없으면 get으로 얻어와야 함.
        tab_count = write(tab_count, code, "HTTP.Request theRequest = new HTTP.Request(\"get\", web_address + \"#{action}\" + args);")
      else
        tab_count = write(tab_count, code, "HTTP.Request theRequest = new HTTP.Request(\"post\", web_address + \"#{action}\" + args, hash);")
      end
    end
    
    tab_count = write(tab_count, code, "theRequest.synchronous = sync;")
    tab_count = write(tab_count, code, "theRequest.Send((request) =>")
    tab_count = write(tab_count, code, "{")

	  tab_count = error_handling_code(tab_count, code)
    tab_count = data_mapping_code(tab_count, code, container_type, key, key_type, class_name, column_length, rows, result, nil)
           
    if result == "multi"
      tab_count = write(tab_count, code, "dic.Add(instance.#{key}, instance);")
      tab_count = write(tab_count, code, "}")   
    end
           
    if param == "multi"           
      tab_count = write(tab_count, code, "if(callback != null)")
      tab_count = write(tab_count, code, "{")
      tab_count = write(tab_count, code, "callback(#{callback_type(result)});")
      tab_count = write(tab_count, code, "}")
      
      tab_count = write(tab_count, code, "PopupUtil.remove_web_lock_count();")
            
      tab_count = write(tab_count, code, "});")
      tab_count = write(tab_count, code, "}")
      
      #retry 코드 작성
      tab_count = write(tab_count, code, "public static bool retry()")
      tab_count = write(tab_count, code, "{")
      
      if param == "multi"
        tab_count = write(tab_count, code, "Call(dict_, args_, callback_, sync_);")
      elsif param == "custom"
        tab_count = write(tab_count, code, "Call(hash_, args_, callback_, sync_);")
      elsif param == "none"
        tab_count = write(tab_count, code, "Call(args_, callback_, sync_);")
      else
        tab_count = write(tab_count, code, "Call(inst_, args_, callback_, sync_);")
      end
      
      tab_count = write(tab_count, code, "return true;")      
      tab_count = write(tab_count, code, "}")
      tab_count = write(tab_count, code, "}")
      
    elsif param == "custom"
      # json_obj      
    elsif param == "single"
      tab_count = write(tab_count, code, "if(callback != null)")
      tab_count = write(tab_count, code, "{")
      tab_count = write(tab_count, code, "callback(#{callback_type(result)});")
      
        
      tab_count = write(tab_count, code, "}")     
      tab_count = write(tab_count, code, "PopupUtil.remove_web_lock_count();")
      tab_count = write(tab_count, code, "});")
      tab_count = write(tab_count, code, "}")

      #retry 코드 작성
      tab_count = write(tab_count, code, "public static bool retry()")
      tab_count = write(tab_count, code, "{")
      
      if param == "multi"
        tab_count = write(tab_count, code, "Call(dict_, args_, callback_, sync_);")
      elsif param == "custom"
        tab_count = write(tab_count, code, "Call(hash_, args_, callback_, sync_);")
      elsif param == "none"
        tab_count = write(tab_count, code, "Call(args_, callback_, sync_);")
      else
        tab_count = write(tab_count, code, "Call(inst_, args_, callback_, sync_);")
      end
      
      tab_count = write(tab_count, code, "return true;")
      tab_count = write(tab_count, code, "}")
      tab_count = write(tab_count, code, "}")
    else
      puts "invalid option." + " param : " + param + " result : " + result 
      return false
    end
    
    code = header + code
    
    dir = "#{destination}\\Assets\\Scripts\\Http\\"
    if Dir.exists?(dir) == false
      FileUtils::mkdir_p(dir)
    end

  	if action == nil  
  		file = File.open("#{dir}\\#{class_name}_Http_update.cs", 'w') 
  	else
  		file = File.open("#{dir}\\#{tag}_Http_update.cs", 'w') 
  	end

    file.write(code)
  end
    
  def self.json_to_loader_class(destination, class_name, rows, column_length, key, option)
    if option.include? "multimap"
      container_type = "MultiSortedDictionary"
    else
      container_type = "Dictionary"
    end
    
    tab_count = 0
    header = using_code()
      
    key_type = String.new
    
    for value in 0...column_length
      name = rows[0][value]
      type = rows[1][value]
      
      if name == key
        key_type = type
      end
    end
    
    file_read, result = parse_json_option(option)
    
    code = String.new
    
    if result == "multi"
      return_type = "#{container_type}<#{key_type}, #{class_name}>"
    else
      return_type = "#{class_name}"
    end
    
    if file_read
      tab_count = write(tab_count, code, "public class #{class_name}_Loader : ScriptableObject {")
      tab_count = write(tab_count, code, "public static #{return_type} Get() {")
      tab_count = write(tab_count, code, "string textValue = Util.read_string_from_json(\"#{class_name}.json\");")
      tab_count = write(tab_count, code, "JSONObject json_obj = new JSONObject(textValue);")
      tab_count = write(tab_count, code, "#{container_type}<#{key_type}, #{class_name}> dic = new #{container_type}<#{key_type}, #{class_name}>();")
    else
      tab_count = write(tab_count, code, "public class JSON_to_#{class_name} : ScriptableObject {")
      tab_count = write(tab_count, code, "public static #{return_type} Get(JSONObject json_obj) {")
      tab_count = write(tab_count, code, "#{class_name} instance = null;")
    end

    tab_count = data_mapping_code(tab_count, code, container_type, key, key_type, class_name, column_length, rows, result, file_read)

    if result == "multi"    
      tab_count = write(tab_count, code, "dic.Add(instance.#{key}, instance);")
      tab_count = write(tab_count, code, "}")
      tab_count = write(tab_count, code, "return dic;")
    else
      tab_count = write(tab_count, code, "return instance;")
    end
    
    tab_count = write(tab_count, code, "}")
    
        
    tab_count = write(tab_count, code, "}")
    
    code = header + code
    
    dir = "#{destination}\\Assets\\Scripts\\Excel"
    if Dir.exists?(dir) == false
      FileUtils::mkdir_p(dir)
    end

    if file_read   
      file = File.open("#{dir}\\#{class_name}_Loader.cs", 'w')
    else
      file = File.open("#{dir}\\#{class_name}_Parser.cs", 'w')
    end
         
    file.write(code)
  end
  
  def self.to_enum(destination, class_name, rows, row_length)
    tab_count = 0
    header = using_code()
    
    code = String.new
    tab_count = write(tab_count, code, "public enum #{class_name} {")
    
    for value in 3...row_length
      name = rows[value][0]
      number = rows[value][1].to_i
            
      tab_count = write(tab_count, code, "#{name} = #{number},")
    end 
    
    tab_count = write(tab_count, code, "}")
    
    code = header + code
    
    dir = "#{destination}\\Assets\\Scripts\\Enum"
    if Dir.exists?(dir) == false
      FileUtils::mkdir_p(dir)
    end
    
    file = File.open("#{dir}\\#{class_name}.cs", 'w') 
    file.write(code)
  end
end