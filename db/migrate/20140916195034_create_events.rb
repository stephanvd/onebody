class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :name
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.references :group
      t.references :person
      t.references :site

      t.timestamps
    end
  end
end
