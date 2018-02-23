require 'find'
require 'json'

require 'active_support/inflector'

require 'rest-client'
require 'thread'

module HashConverter
 
  def self.encode(value, key = nil, out_hash = {})
    case value
    when Hash  then
      value.each { |k,v| encode(v, append_key(key,k), out_hash) }
      out_hash
    when Array then
      value.each { |v| encode(v, "#{key}[]", out_hash) }
      out_hash
    when nil   then ''
    else
      out_hash[key] = value
      out_hash
    end
  end
 
  private
 
  def self.append_key(root_key, key)
    root_key.nil? ? :"#{key}" : :"#{root_key}[#{key.to_s}]"
  end
 
end

class RailsPost

  def self.run(key, sheet_name, address, rows, row_length, column_length)
    #clear_address = address + "clear/"
    #RestClient.get(clear_address.downcase)
    
    #Rails 상에서의 단수 / 복수 구분의 문제 로 인해 Rails와의 연동 부를 위해 복수화를 하는 과정 [pluralize]
    address = address + sheet_name.downcase.pluralize + ".json"
            
    work_q = Queue.new

    for row in 3...row_length
      parameters = Hash.new
      h = Hash.new  

      for column in 0...column_length
        name = rows[0][column]
        type = rows[1][column]
        
        if type.include? "integer"
          h[name] = rows[row][column].to_i
    		elsif type.include? "bool"
		      h[name] = rows[row][column].to_s.downcase == "true" ? 1 : 0
        else
          h[name] = rows[row][column].to_s
        end
        
        if name == key
          key_value = h[name]
        end
        
      end 

      parameters[sheet_name.downcase + "_" + key_value] = h
      www_params = HashConverter.encode(parameters)      
      post(address.downcase, www_params)        

    end

    puts "Rails post completed"
  end
  
  def self.post(address, www_params)
    begin
      RestClient.post(address.downcase, www_params)      
    rescue Exception => e
      if RestClient::Exceptions::EXCEPTIONS_MAP[302] == nil
        puts e.message
      end 
    end
  end        

end