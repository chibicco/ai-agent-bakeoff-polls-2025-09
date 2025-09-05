class CreatePolls < ActiveRecord::Migration[8.0]
  def change
    create_table :polls do |t|
      t.string :title
      t.text :description
      t.string :slug
      t.integer :status
      t.datetime :ends_at

      t.timestamps
    end
    add_index :polls, :slug, unique: true
  end
end
