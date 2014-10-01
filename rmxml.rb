$LOAD_PATH << "System" unless $LOAD_PATH.include?("System")

require 'encoding'
require 'rexml/rexml'
require "rexml/document"

module RMXML
  
  Tag_String = "s"
  Tag_Array = "a"
  Tag_Bignum = "j"
  Tag_Complex = "v"
  Tag_False = "n"
  Tag_Fixnum = "i"  
  Tag_Float = "f"  
  Tag_Hash = "h"
  Tag_Nil = "z"  
  Tag_Object = "o"
  Tag_Range = "r"
  Tag_Rational = "l"
  Tag_Ref = "p"
  Tag_Struct = "u"
  Tag_Symbol = "m"  
  Tag_Time = "t"
  Tag_True = "y"      
  
  
  # List of classes that need to be handled differently  
  def self.save_data(obj, path)
    # create XML. Not sure how to add declaration
    xml = REXML::Document.new
    Generator.generate(xml.root_node, obj)
    
    # write it out
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true # This is the magic line that does what you need!
    File.open(path,"w") do |f|      
      formatter.write(xml, f)
    end
  end
  
  def self.load_data(path)
    f = Kernel.load_data(path)
    doc = REXML::Document.new(f)
    obj = Parser.parse(doc.root_node)
  end
  
  #=============================================================================
  # Main generator class. Figures out how to serialize each object that it gets
  #=============================================================================
  class Generator
  
    Method_Map = {
      Tag_Ref => :add_reference,
      Tag_String => :add_string,
      Tag_Float => :add_float,
      Tag_Fixnum => :add_fixnum,
      Tag_Bignum => :add_bignum,
      Tag_Hash => :add_hash,
      Tag_Symbol => :add_symbol,
      Tag_Array => :add_array,
      Tag_Object => :add_object,
      Tag_True => :add_true,
      Tag_False => :add_false,
      Tag_Range => :add_range,
      Tag_Nil => :add_nil,
      Tag_Complex => :add_complex,
      Tag_Struct => :add_struct,
      Tag_Rational => :add_rational,
      Tag_Time => :add_time,
      
      Table => :add_table,
      Tone  => :add_tone,
      Color => :add_color,
      Rect  => :add_rect  
    }
    
    Type_Map = {
      Array   => Tag_Array,
      Hash => Tag_Hash,
      Fixnum => Tag_Fixnum,
      String => Tag_String,
      Float => Tag_Float,
      Symbol => Tag_Symbol,
      TrueClass => Tag_True,
      FalseClass => Tag_False,
      Range => Tag_Range,
      Struct => Tag_Struct,
      Complex => Tag_Complex,
      Rational => Tag_Rational,      
      Time => Tag_Time,
    }
    
    def self.generate(node, obj)
      @id = 0
      @refs = {}
      return add_node(node, obj)
    end

    def self.add_node(node, obj)
      # Create an element
      tag = get_type(obj)
      child = node.add_element(tag)    
      
      # Fill the element
      method = Method_Map[tag]
      self.send(method, child, obj)
      return child
    end
    
    def self.add_fixnum(node, obj)
      node.text = obj
    end
    
    def self.add_bignum(node, obj)
      node.text = obj
    end
    
    def self.add_hash(node, obj)
      obj.each do |key, val|
        add_node(node, key)
        add_node(node, val)
      end
    end
    
    def self.add_array(node, arr)
      arr.each do |obj|
        add_node(node, obj)
      end
    end
    
    def self.add_float(node, obj)
      node.text = obj
    end
    
    def self.add_nil(node, obj)
    end
    
    def self.add_true(node, obj)
    end
    
    def self.add_false(node, obj)
    end
    
    def self.add_string(node, obj)
      node.text = obj
    end
    
    def self.add_symbol(node, obj)
      node.text = obj
    end
    
    def self.add_rational(node, obj)
      add_node(node, obj.numerator)
      add_node(node, obj.denominator)
    end
    
    def self.add_complex(node, obj)
      add_node(node, obj.real)
      add_node(node, obj.imag)
    end
    
    def self.add_struct(node, obj)
      node.attributes["c"] = obj.xml_class.name
      node.attributes["id"] = @id
      @refs[obj] = @id
      @id += 1

      obj.each_pair do |key, val|        
        child = add_node(node, val)        
        child.attributes["a"] = key
      end
    end
    
    def self.add_time(node, obj)
      add_node(node, obj.year)
      add_node(node, obj.month)
      add_node(node, obj.day)
      add_node(node, obj.hour)
      add_node(node, obj.min)
      add_node(node, obj.sec)
      add_node(node, obj.utc_offset)
    end
    
    def self.add_range(node, obj)
      child = node.add_element("i")
      child.attributes["a"] = "begin"
      child.text = obj.begin
      
      child = node.add_element("i")
      child.attributes["a"] = "end"
      child.text = obj.end

      tag = obj.exclude_end? ? "y" : "n"
      child = node.add_element(tag)
      child.attributes["a"] = "exclude_end"
    end
    
    def self.add_reference(node, obj)
      node.text = @refs[obj]
    end
    
    def self.add_object(node, obj)
      node.attributes["c"] = obj.xml_class.name
      node.attributes["id"] = @id
      @refs[obj] = @id
      @id+= 1
      
      
      method = Method_Map[obj.xml_class]
      # Special objects
      if method
        self.send(method, node, obj)
        
      # Normal objects
      else
        obj.instance_variables.each do |ivar|
          val = obj.instance_variable_get(ivar)
          child = add_node(node, val)
          child.attributes["a"] = ivar
        end
      end
    end
    
    def self.add_table(node, obj)
      add_node(node, obj.xsize)
      add_node(node, obj.ysize)
      add_node(node, obj.zsize)
      data = []
      for z in 0...obj.zsize
        for y in 0...obj.ysize
          for x in 0...obj.xsize
            data << obj[x,y,z]
          end
        end
      end
      add_node(node, data)
    end
    
    def self.add_color(node, obj)
      add_node(node, obj.red)
      add_node(node, obj.green)
      add_node(node, obj.blue)
      add_node(node, obj.alpha)
    end
    
    def self.add_tone(node, obj)
      add_node(node, obj.red)
      add_node(node, obj.green)
      add_node(node, obj.blue)
      add_node(node, obj.gray)
    end
    
    def self.add_rect(node, obj)
      add_node(node, obj.x)
      add_node(node, obj.y)
      add_node(node, obj.width)
      add_node(node, obj.height)
    end
    
    def self.get_type(obj)
      type = Type_Map[obj.xml_class]
      if obj.nil?
        Tag_Nil
      elsif @refs.include?(obj)
        Tag_Ref
      elsif type
        type
      else
        Tag_Object
      end
    end
  end
  
  #=============================================================================
  # Main parser class. Takes XML data and builds a Ruby object.
  #=============================================================================
  
  class Parser
    
    Method_Map = {
      Tag_Array  => :load_array,
      Tag_String => :load_string,
      Tag_Hash   => :load_hash,
      Tag_Fixnum => :load_fixnum,
      Tag_Bignum => :load_bignum,
      Tag_Float  => :load_float,
      Tag_Symbol => :load_symbol,
      Tag_Object => :load_object,
      Tag_True   => :load_true,
      Tag_False  => :load_false,
      Tag_Nil    => :load_nil,
      Tag_Ref    => :load_ref,
      Tag_Complex => :load_complex,
      Tag_Time => :load_time,
      Tag_Struct => :load_struct,
      Tag_Range  => :load_range,
      Tag_Rational => :load_rational
    }
    
    Class_Map = {
      "Rect"  => :load_rect,
      "Table" => :load_table,
      "Color" => :load_color,
      "Tone"  => :load_tone
    }
    
    def self.parse(node)
      @refs = {}
      load_node(node.elements[1])
    end
  
    def self.load_node(node)
      return unless node
      method = Method_Map[node.name]
      return method ? self.send(method, node) : nil
    end
    
    def self.build_object(node)
      class_name = node.attributes["c"]
      clazz = class_name.split('::').inject(Object) {|o,c| o.const_get c}
      return clazz.allocate
    end
    
    def self.load_object(node)
      obj = build_object(node)
      
      # store this object for reference
      id = node.attributes["id"]
      @refs[id] = obj
      
      # Build custom object
      method = Class_Map[node.attributes["c"]]
      if method
        self.send(method, node, obj)
      # Build regular object
      else
        node.elements.each do |elmt|
          attr_name = elmt.attributes["a"]
          data = load_node(elmt)
          obj.instance_variable_set(attr_name, data)
        end
      end
      return obj
    end
    
    def self.load_array(node)
      obj = []
      node.elements.each do |elmt|
        obj << load_node(elmt)
      end
      obj
    end
    
    def self.load_string(node)
      return node.text
    end
    
    def self.load_hash(node)
      obj = {}
      for i in 1...node.elements.size
        key = load_node(node.elements[i])
        value = load_node(node.elements[i+1])
        obj[key] = value
        i+=1
      end
      obj
    end
    
    def self.load_fixnum(node)
      return node.text.to_i
    end
    
    def self.load_bignum(node)
      return node.text.to_i
    end
    
    def self.load_float(node)
      return node.text.to_f
    end
    
    def self.load_symbol(node)
      return node.text.to_sym
    end
    
    def self.load_struct(node)
      obj = build_object(node)
      node.elements.each do |elmt|
        key = elmt.attributes["a"]
        value = load_node(elmt)
        obj[key] = value
      end
      return obj
    end
    
    def self.load_complex(node)
      real = load_node(node.elements[1])
      imag = load_node(node.elements[2])
      return Complex(real, imag)
    end
    
    def self.load_true(node)
      return true
    end
    
    def self.load_false(node)
      return false
    end
    
    def self.load_nil(node)
      return nil
    end
    
    def self.load_range(node)
      start = load_node(node.elements[1])
      fin = load_node(node.elements[2])
      excl_end = load_node(node.elements[3])
      return Range.new(start, fin, excl_end)      
    end
    
    def self.load_rational(node)
      numer = load_node(node.elements[1])
      denom = load_node(node.elements[2])
      return Rational(numer, denom)
    end
    
    def self.load_ref(node)
      id = node.text
      return @refs[id]
    end
    
    def self.load_time(node)
      year = load_node(node.elements[1])
      month = load_node(node.elements[2])
      day = load_node(node.elements[3])
      hour = load_node(node.elements[4])
      min = load_node(node.elements[5])
      sec = load_node(node.elements[6])
      utc_offset = load_node(node.elements[7])
      return Time.new(year, month, day, hour, min, sec, utc_offset)
    end
    
    def self.load_rect(node, obj)
      obj.x = load_node(node.elements[1])
      obj.y = load_node(node.elements[2])
      obj.width = load_node(node.elements[3])
      obj.height = load_node(node.elements[4])
    end
    
    def self.load_tone(node, obj)
      obj.red = load_node(node.elements[1])      
      obj.green = load_node(node.elements[2])
      obj.blue = load_node(node.elements[3])
      obj.gray = load_node(node.elements[4])
    end
    
    def self.load_color(node, obj)
      obj.red = load_node(node.elements[1])      
      obj.green = load_node(node.elements[2])
      obj.blue = load_node(node.elements[3])
      obj.alpha = load_node(node.elements[4])
    end
    
    def self.load_table(node, obj)
      xsize = load_node(node.elements[1])
      ysize = load_node(node.elements[2])
      zsize = load_node(node.elements[3])
      data = load_node(node.elements[4])
      obj.resize(xsize, ysize, zsize)
      for z in 0...obj.zsize
        for y in 0...obj.ysize
          for x in 0...obj.xsize
            obj[x,y,z] = data[z * zsize + y * ysize + x]
          end
        end
      end
    end
  end
end

class Object
  alias :xml_class :class
end
