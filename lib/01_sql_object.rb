require_relative 'db_connection'
require 'active_support/inflector'

 # bundle exec rspec spec/01_sql_object_spec.rb
class SQLObject
  def self.columns

    query = <<-SQL
    SELECT *
    FROM "#{table_name}"
    SQL

    #first result in query returns array of string table names
    tables = DBConnection.execute2(query)
    @columns = tables.first.map(&:to_sym)
    #must convert them to symbols to store our object values
  end

  def self.finalize!

    #meta create getter and setters for each 
    #value in self.columns
    #must call self.columns because we need to be in the class
    #to access the class method columns

    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  def self.all

    query = <<-SQL
      SELECT * 
      FROM "#{table_name}"
    SQL

    #returns an array of all raw hash objects containing the table row data
    results = DBConnection.execute(query)
    #parse_all converts raw hash rable row into a new instance of the object
    parse_all(results)

  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)

  result = DBConnection.execute(<<-SQL, id)
      SELECT
    #{ table_name }.*
      FROM
    #{ table_name }
      WHERE
    #{ table_name }.id = ?
    SQL

    #returns all queried values in an array
    #even if it searched for just one object
    #we must access it from the array
    parse_all(result).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      #iterate through params hash setting each key to a symbol
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        #check if the class columns contains the attr_name
        self.send("#{ attr_name }=", value)
        #use send to call the attribute setter to value passed in
      else
        raise "unknown attribute '#{attr_name}'"
        #there is no column in the table for the attribute
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
  end

  def insert
    col_names = self.columns
    question_marks = ["?"] * col_names.length
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
