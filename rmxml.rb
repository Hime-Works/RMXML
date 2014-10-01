$LOAD_PATH << "System" unless $LOAD_PATH.include?("System")

require 'encoding'
require 'rexml/rexml'
require "rexml/document"

module RMXML
  
  Tag_String = "s"
  Tag_Array = "a"
  Tag_Fixnum = "i"
  Tag_Bignum = "j"
  Tag_Float = "f"
  Tag_Object = "o"
  Tag_Hash = "h"
  Tag_Symbol = "m"
  Tag_False = "n"
  Tag_True = "y"
  Tag_Nil = "z"
  Tag_Ref = "p"
  Tag_Range = "r"
  
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
      Tag_Nil => :add_nil
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
      obj.instance_variables.each do |ivar|
        val = obj.instance_variable_get(ivar)
        child = add_node(node, val)
        child.attributes["a"] = ivar
      end
    end
    
    def self.get_type(obj)
      if obj.nil?
        Tag_Nil
      elsif @refs.include?(obj)
        Tag_Ref
      elsif obj.is_a?(Array)
        Tag_Array
      elsif obj.is_a?(Hash)
        Tag_Hash
      elsif obj.is_a?(Fixnum)
        Tag_Fixnum
      elsif obj.is_a?(String)
        Tag_String
      elsif obj.is_a?(Float)
        Tag_Float
      elsif obj.is_a?(Symbol)
        Tag_Symbol
      elsif obj.is_a?(TrueClass)
        Tag_True
      elsif obj.is_a?(FalseClass)
        Tag_False
      elsif obj.is_a?(Range)
        Tag_Range
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
      Tag_Range  => :load_range
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
      
      # Build the object
      node.elements.each do |elmt|
        attr_name = elmt.attributes["a"]
        data = load_node(elmt)
        obj.instance_variable_set(attr_name, data)
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
    
    def self.load_ref(node)
      id = node.text
      return @refs[id]
    end
  end
end

class Object
  alias :xml_class :class
end
