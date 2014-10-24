require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns

    query = <<-SQL
    SELECT *
    FROM "#{table_name}"
    SQL

    #first result in query returns array of string table names
    tables = DBConnection.execute(query)
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

    #returns an array of all raw hash objs containing the table row data
    #parse_all converts raw hash rable row into a new instance of the object
    
    results = DBConnection.execute(query)
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
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        #check if the class columns contains the attr_name
        #use send to call the attribute setter to value passed in
        self.send("#{ attr_name }=", value)
      else
        raise "unknown attribute '#{attr_name}'"
        #there is no column in the table for the given attribute
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  #this is an instance method so we must call self.class.columns to access columns

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    col_names = self.class.columns.map(&:to_s).join(", ")
    question_marks = (["?"] * self.class.columns.length).join(", ")

    #stringify column names and join them with commas
    #create a question mark for each column value join to string with commas

    DBConnection.execute(<<-SQL, *attribute_values)
        INSERT INTO
          #{ self.class.table_name } (#{ col_names })
        VALUES
          (#{ question_marks })
      SQL

      self.id = DBConnection.last_insert_row_id
  end

  def update

    #generate "col3 = ?, col2 = ?," format
    #pass in magic attribute_values as well as ID

   format_attrs = self.class.columns
        .map { |attr| "#{ attr } = ?" }.join(", ")

      DBConnection.execute(<<-SQL, *attribute_values, id)
        UPDATE
          #{ self.class.table_name }
        SET
          #{ format_attrs }
        WHERE
          #{ self.class.table_name }.id = ?
      SQL
    end

  def save
    id.nil? ? insert : update
  end

end
