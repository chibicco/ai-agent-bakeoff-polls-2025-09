class CreateChoices < ActiveRecord::Migration[8.0]
  def change
    create_table :choices do |t|
      t.references :poll, null: false, foreign_key: true
      t.string :label
      t.integer :votes_count, default: 0, null: false

      t.timestamps
    end
  end
end
