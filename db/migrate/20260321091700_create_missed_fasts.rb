class CreateMissedFasts < ActiveRecord::Migration[8.1]
  def change
    create_table :missed_fasts do |t|
      t.references :user, null: false, foreign_key: true
      t.date :missed_on, null: false
      t.text :notes

      t.timestamps
    end

    add_index :missed_fasts, [ :user_id, :missed_on ], unique: true
  end
end
