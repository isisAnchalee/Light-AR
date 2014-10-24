require_relative '02_searchable'
require 'active_support/inflector'
 # bundle exec rspec spec/03_associatable_spec.rb

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    #go from a class name to a class object
     @class_name.constantize
  end

  def table_name
    #call object.table_name to get associated table
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
#self object belongs to name
def initialize(name, options = {})
    defaults = {
      :foreign_key => "#{name}_id".to_sym,
      :class_name => name.to_s.camelcase,
      :primary_key => :id
    }
    #creates default values
    #option to override default values with options hash
    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end

end

class HasManyOptions < AssocOptions
  #name obj belongs to self obj
   def initialize(name, self_class_name, options = {})
    defaults = {
      :foreign_key => "#{self_class_name.underscore}_id".to_sym,
      :class_name => name.to_s.singularize.camelcase,
      :primary_key => :id
    }
  #override default values if you choose
    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

module Associatable
  # Phase IIIb
 def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    #use define_method (name) to create association method with name
    define_method(name) do
      associations_options = self.class.assoc_options[name]
      #send gets :foreign_key
      #model_class gets :class_name
      #Use "where" to select models where the 
      #:primary_key column is equal to the foreign key value.
      fkey_val = self.send(associations_options.foreign_key)
      associations_options.model_class
        .where(associations_options.primary_key => fkey_val).first
        #return the instance of the object with matching primary key
    end
  end

 def has_many(name, options = {})
    self.assoc_options[name] =
      HasManyOptions.new(name, self.name, options)
      #stores the object type of association options in assoc_options
      #creates an association method with (name)
    define_method(name) do
      associations_options = self.class.assoc_options[name]
      #access primary key 
      pkey_val = self.send(associations_options.primary_key)
      associations_options
        .model_class
        .where(associations_options.foreign_key => pkey_val)
      #returns array of all instances of name objects
    end
  end

  def assoc_options
    #key = assoc object name. 
    #value = new association object with data
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
