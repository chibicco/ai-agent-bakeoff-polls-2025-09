class CreateChoices < ActiveRecord::Migration[8.0]
  def change
    create_table :choices do |t|
      t.references :poll, null: false, foreign_key: true, index: true
      t.string :label, null: false
      t.integer :votes_count, null: false, default: 0

      t.timestamps
    end
  end
end

