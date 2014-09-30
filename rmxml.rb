$LOAD_PATH << "System" unless $LOAD_PATH.include?("System")

require 'encoding'
require 'rexml/rexml'
require "rexml/document"

# Purely for example purposes

def parse
  f = File.new("demo.xml")
  doc = REXML::Document.new(f)
  p doc.to_s
end

def create
  a = $data_actors[1]
  doc = REXML::Document.new
  
  objs = [a]
  objs.each do |obj|
    class_name = obj.class.to_s.gsub("RPG::", "RPG--")
    node = doc.add_element(class_name)
    obj.instance_variables.each do |ivar|
      attr_name = ivar.to_s.gsub("@", "")
      dat = obj.instance_variable_get(ivar)
      if dat.is_a?(Enumerable)
        p dat
      else
        node.attributes[attr_name] = dat
      end
    end
  end
  p doc.to_s
  File.open("demo.xml","w") do |data|
    data<<doc
  end
end