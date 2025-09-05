class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      t.references :poll, null: false, foreign_key: true, index: true
      t.references :choice, null: false, foreign_key: true, index: true
      t.string :voter_hash

      t.timestamps
    end

    # voter_hash が NULL でない場合のみ、(poll_id, voter_hash) を一意にする
    add_index :votes, [:poll_id, :voter_hash], unique: true, where: "voter_hash IS NOT NULL"
  end
end

