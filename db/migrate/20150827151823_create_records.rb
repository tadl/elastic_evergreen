class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.text :title
      t.text :author
      t.string :record_id
      t.text :e_resource
      t.text :abstract
      t.text :contents
      t.text :format_type
      t.string :record_year
      t.string :call_number
      t.text :publisher
      t.text :publisher_location
      t.text :isbn, array: true
      t.text :physical_description
      t.json :subject
      t.text :genre, array: true
      t.text :series, array: true
      t.json :availability

      t.timestamps
    end
  end
end
