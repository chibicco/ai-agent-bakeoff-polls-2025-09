class CreatePolls < ActiveRecord::Migration[8.0]
  def change
    create_table :polls do |t|
      t.string :title, null: false
      t.text :description
      t.string :slug, null: false
      t.integer :status, null: false, default: 0
      t.datetime :ends_at

      t.timestamps
    end

    add_index :polls, :slug, unique: true
  end
end

